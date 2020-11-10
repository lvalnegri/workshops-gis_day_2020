#################################
# GIS DAY 2020 * DATA WRANGLING #
#################################

# load packages
pkgs <- c('data.table', 'fst', 'rgdal', 'rgeos', 'rmapshaper', 'sp')
lapply(pkgs, require, char = TRUE)

# lookups
y <- read_fst('./data/lookups', as.data.table = TRUE)
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

# Boundaries

## MSOA

bnd <- readOGR('./boundaries', 'MSOA', stringsAsFactors = 'FALSE')
# check crs and id name
summary(bnd)
# if not wgs84 transform
bnd <- spTransform(bnd, CRS('+init=epsg:4326'))
# keep in data slot only id, name and area, renaming as 'MSOA', 'nameons', 'area'
bnd <- bnd[, c('MSOA11CD', 'MSOA11NM', 'Shape__Are')]
colnames(bnd@data) <- c('MSOA', 'nameons', 'area')
# reassign the polygon IDs
bnd <- spChFIDs(bnd, bnd$MSOA)
# if not generalized, simplify the polygon
bnd <- ms_simplify(bnd)
# delete Wales 
bnd <- subset(bnd, substring(bnd$MSOA, 1, 1) == 'E')
# extract area and add to dataset
yt <- setDT(bnd@data[, c('MSOA', 'area')])
y <- yt[y, on = 'MSOA']
setcolorder(y, yn)
# save dataset
write_fst(y, './data/MSOA')
# save boundaries
saveRDS(bnd, './boundaries/MSOA')

## LTLA built from MSOA using dissolving

# add LTLA codes to MSOA boundaries
bnd.l <- merge(bnd, y[, .(MSOA, LTLA)], by = 'MSOA')
bnd.l <- raster::aggregate(bnd.l, 'LTLA')
saveRDS(bnd.l, './boundaries/LTLA')


## Clean and Exit
rm(list = ls())
gc()


