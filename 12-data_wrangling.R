#################################
# GIS DAY 2020 * DATA WRANGLING #
#################################

### load packages -----
pkgs <- c('data.table', 'fst', 'raster', 'rgdal', 'rgeos', 'rmapshaper', 'sp')
lapply(pkgs, require, char = TRUE)


### MSOA -----

# start from the GOV lookups table
y <- read_fst('./data/msoa_ltla_utla_rgn', as.data.table = TRUE)
yn <- names(y)

# HoC Names 
yt <- read_fst('./data/msoa_names', as.data.table = TRUE)
y <- yt[y, on = 'MSOA']
setcolorder(y, yn)
yn <- names(y)

# population
yt <- read_fst('./data/population', as.data.table = TRUE)
y <- yt[, .(MSOA, population = TOT)][y, on = 'MSOA']
setcolorder(y, yn)
yn <- names(y)
sum(y$population) # 56,286,961 check -> https://en.wikipedia.org/wiki/Demography_of_England

# population by age
yt[, TOT := NULL]
yt <- melt(yt, id.vars = 'MSOA', variable.factor = FALSE, value.name = 'count')
yt[, variable := as.numeric(gsub('X', '', variable))]
yt[, tmp := cut(variable, breaks = seq(0, 90, 5), right = FALSE, labels = FALSE)]
yt[, age := paste0(min(variable), '-', max(variable)), tmp ]
yt[variable == 90, age := '90+']
# chk <- yt[, sum(count), .(variable, tmp, age)]
yt[, c('variable', 'tmp') := NULL]
yt <- rbindlist(list( yt[, .(count = sum(count)), .(MSOA, age)], yt[, .(count = sum(count)), .(MSOA, age = ifelse(age < 60, '0-59', '60+'))] ))
yt[, age := factor(age, levels = unique(age), ordered = TRUE)]
yt <- dcast(yt, MSOA~age)
setnames(yt, c('MSOA', paste0('pop_', names(yt)[2:ncol(yt)])))
y <- yt[y, on = 'MSOA']
# all.equal(sum(y$population), sum(y$`pop_0-59`, y$`pop_60+`), sum(y[, `pop_0-4`:`pop_90+`]))
setcolorder(y, yn)
yn <- names(y)

# IMD
yt <- read_fst('./data/imd', as.data.table = TRUE)
ym <- read_fst('./data/lsoa_msoa', as.data.table = TRUE)
ym <- ym[yt, on = 'LSOA'][, LSOA := NULL]
ym <- ym[, .(IMD = mean(IMD)), MSOA][order(-IMD)][, `:=`(
        rIMD = 1:.N,
        dIMD = 11 - cut(IMD, quantile(IMD, seq(0, 1, 0.1)), include.lowest = TRUE, labels = FALSE)
)]
y <- ym[y, on = 'MSOA']
setcolorder(y, yn)
yn <- names(y)

# income
yt <- read_fst('./data/income', as.data.table = TRUE)
y <- yt[y, on = 'MSOA']
setcolorder(y, yn)
yn <- names(y)

# house prices
yt <- read_fst('./data/house_prices', as.data.table = TRUE)
y <- yt[y, on = 'MSOA']
setcolorder(y, yn)
yn <- names(y)

# consumption
yt <- read_fst('./data/consumption', as.data.table = TRUE)
y <- yt[y, on = 'MSOA']
setcolorder(y, yn)
yn <- names(y)

# save
write_fst(y, './data/MSOA')

### LSOA -----

# start from the NHS lookups table
y <- read_fst('./data/lsoa_ccg_stp_cal', as.data.table = TRUE)
yn <- names(y)

# population
yt <- read_fst('./data/population_lsoa', as.data.table = TRUE)
y <- yt[, .(LSOA, population = TOT)][y, on = 'LSOA']
setcolorder(y, yn)
yn <- names(y)
sum(y$population) # 56,286,961 check -> https://en.wikipedia.org/wiki/Demography_of_England

# population by sex and age 
# !!==> insert some code here <==!!

# IMD
yt <- read_fst('./data/imd', as.data.table = TRUE)
y <- yt[y, on = 'LSOA']
setcolorder(y, yn)

# save
write_fst(y, './data/LSOA')


### TRUSTS -----

y <- read_fst('./data/trusts', as.data.table = TRUE)

# cleaning postcodes, then adding coordinates + LSOA
y[nchar(PCU) == 5, PCU := paste0(substr(PCU, 1, 2), '  ', substring(PCU, 3))]
y[nchar(PCU) == 6, PCU := paste0(substr(PCU, 1, 3), ' ', substring(PCU, 4))]
y[nchar(PCU) == 8, PCU := gsub(' ', '', PCU)]
pc <- read_fst('./data/postcodes', columns = c('PCU', 'x_lon', 'y_lat', 'LSOA', 'MSOA', 'CCG'), as.data.table = TRUE)
y <- pc[y, on = 'PCU']

# cleaning names
y[, TRSTn := tolower(gsub("\\s+", " ", trimws(TRSTn)))]
y[, TRSTn := gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", TRSTn, perl = TRUE)]
y[, TRSTn := gsub('Nhs', 'NHS', TRSTn)]

# adding flag
y[, is_foundation := 0][grepl('Foundation', TRSTn), is_foundation := 1]

# save as dataframe
setcolorder(y, c('TRST', 'TRSTn', 'x_lon', 'y_lat'))
write_fst(y, './data/TRST')

# converting and save as spatial object
coordinates(y) <- ~x_lon+y_lat
proj4string(y) <- CRS('+init=epsg:4326')
saveRDS(y, './boundaries/TRST')

### Boundaries -----

## MSOA
bnd <- readOGR('./boundaries', 'MSOA', stringsAsFactors = 'FALSE')
# check crs and id name
summary(bnd)
# if not wgs84 transform
bnd <- spTransform(bnd, CRS('+init=epsg:4326'))
# extract area and namesons, then add to lsoa_... dataset and save
y <- read_fst('./data/MSOA', as.data.table = TRUE)
y[, c('MSOAnons', 'area') := NULL]
yt <- setDT(bnd@data[, c('MSOA11CD', 'MSOA11NM', 'Shape__Are')])
setnames(yt, c('MSOA', 'MSOAnons', 'area'))
y <- yt[y, on = 'MSOA']
setcolorder(y, c('MSOA', 'MSOAn', 'MSOAnons', 'area', 'LTLA', 'LTLAn', 'UTLA', 'UTLAn'))
write_fst(y, './data/MSOA')
# keep in data slot only the id and rename
bnd <- bnd[, c('MSOA11CD')]
colnames(bnd@data) <- c('MSOA')
# reassign the polygon IDs
bnd <- spChFIDs(bnd, bnd$MSOA)
# delete Wales 
bnd <- subset(bnd, substring(bnd$MSOA, 1, 1) == 'E')
# if not generalized, simplify the polygon (but be careful, it takes a while...)
bnd <- ms_simplify(bnd)
# save boundaries
saveRDS(bnd, './boundaries/MSOA')

### LTLA built from MSOA using dissolving
bnd.y <- merge(bnd, y[, .(MSOA, LTLA)], by = 'MSOA')
bnd.y <- aggregate(bnd.y, 'LTLA')
plot(bnd.y)
saveRDS(bnd.y, './boundaries/LTLA')
yt <- y[, .(area = sum(area), population = sum(population)), .(LTLA, LTLAn, UTLA, UTLAn, RGN, RGNn)][order(LTLA)]
write_fst(yt, './data/LTLA')

### UTLA built from MSOA using dissolving
bnd.y <- merge(bnd, y[, .(MSOA, UTLA)], by = 'MSOA')
bnd.y <- aggregate(bnd.y, 'UTLA')
plot(bnd.y)
saveRDS(bnd.y, './boundaries/UTLA')
yt <- y[, .(area = sum(area), population = sum(population)), .(UTLA, UTLAn, RGN, RGNn)][order(UTLA)]
write_fst(yt, './data/UTLA')

### RGN built from MSOA using dissolving
bnd.y <- merge(bnd, y[, .(MSOA, RGN)], by = 'MSOA')
bnd.y <- aggregate(bnd.y, 'RGN')
plot(bnd.y)
saveRDS(bnd.y, './boundaries/RGN')
yt <- y[, .(area = sum(area), population = sum(population)), .(RGN, RGNn)][order(RGN)]
write_fst(yt, './data/RGN')

## LSOA
bnd <- readOGR('./boundaries', 'LSOA', stringsAsFactors = 'FALSE')
# check crs and id name
summary(bnd)
# if not wgs84 transform
bnd <- spTransform(bnd, CRS('+init=epsg:4326'))
# extract area and namesons, then add to lsoa_... dataset and save
y <- read_fst('./data/LSOA', as.data.table = TRUE)
y[, c('LSOAn', 'area') := NULL]
yt <- setDT(bnd@data[, c('LSOA11CD', 'LSOA11NM', 'Shape__Are')])
setnames(yt, c('LSOA', 'LSOAn', 'area'))
y <- yt[y, on = 'LSOA']
write_fst(y, './data/LSOA')
# keep in data slot only the id and rename
bnd <- bnd[, c('LSOA11CD')]
colnames(bnd@data) <- c('LSOA')
# reassign the polygon IDs
bnd <- spChFIDs(bnd, bnd$LSOA)
# delete Wales 
bnd <- subset(bnd, substring(bnd$LSOA, 1, 1) == 'E')
# if not generalized, simplify the polygon (but be careful, it takes a while...)
bnd <- ms_simplify(bnd)
# save boundaries
saveRDS(bnd, './boundaries/LSOA')

## CCG built from LSOA using dissolving
bnd.y <- merge(bnd, y[, .(LSOA, CCG)], by = 'LSOA')
bnd.y <- aggregate(bnd.y, 'CCG')
plot(bnd.y)
saveRDS(bnd.y, './boundaries/CCG')
yt <- y[, .(area = sum(area), population = sum(population)), .(CCG, CCGnhs, CCGn, STP, STPn, CAL, CALn)][order(CCG)]
write_fst(yt, './data/CCG')

## STP built from LSOA using dissolving
bnd.y <- merge(bnd, y[, .(LSOA, STP)], by = 'LSOA')
bnd.y <- aggregate(bnd.y, 'STP')
plot(bnd.y)
saveRDS(bnd.y, './boundaries/STP')
yt <- y[, .(area = sum(area), population = sum(population)), .(STP, STPn, CAL, CALn)][order(STP)]
write_fst(yt, './data/STP')

## CAL built from LSOA using dissolving
bnd.y <- merge(bnd, y[, .(LSOA, CAL)], by = 'LSOA')
bnd.y <- aggregate(bnd.y, 'CAL')
plot(bnd.y)
saveRDS(bnd.y, './boundaries/CAL')
yt <- y[, .(area = sum(area), population = sum(population)), .(CAL, CALn)][order(CAL)]
write_fst(yt, './data/CAL')


### save all datasets and boundaries in unique lists -----
lcns <- c('LSOA', 'MSOA', 'LTLA', 'UTLA', 'RGN', 'CCG', 'STP', 'CAL', 'TRST')
y <- lapply(lcns, function(x) read_fst(paste0('./data/', x), as.data.table = TRUE))
names(y) <- lcns
saveRDS(y, './data/datasets')
y <- lapply(lcns, function(x) readRDS(paste0('./boundaries/', x)))
names(y) <- lcns
saveRDS(y, './boundaries/boundaries')

### TEST. Using <stamen> map as google now requires API key
library(ggmap)
yy <- y[['LSOA']]
ylsoa <- read_fst('./data/LSOA', as.data.table = TRUE)
nm <- 'South East London'
yyl <- subset(yy, yy$LSOA %in% ylsoa[CALn %chin% nm, LSOA])
plot(yyl)
mp <- get_stamenmap(bbox = c(yyl@bbox[1,1], yyl@bbox[2,1], yyl@bbox[1,2], yyl@bbox[2,2]), zoom = 10, maptype = 'toner-lite')
yylf <- fortify(yyl) 
gp <- ggmap(mp) +
    geom_path(data = yylf, aes(x = long, y = lat, group = group), color = 'red', size = .2) +
    theme_void() +
    ggtitle(nm) +
    theme( plot.title = element_text(colour = 'orange'), panel.border = element_rect(colour = 'grey', fill = NA, size = 2))
gp
ggsave(gp, device = 'png',filename = 'LSOA_SE.png', path = './outputs/')

### Clean and Exit -----
rm(list = ls())
gc()


