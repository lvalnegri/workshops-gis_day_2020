#################################
# GIS DAY 2020 * DOTSMAP TRUSTS #
#################################

# load packages
pkgs <- c('data.table', 'fst', 'leaflet', 'leaflet.extras', 'leaflet.extras2')
lapply(pkgs, require, char = TRUE)

bnd <- readRDS('./boundaries/MSOA')
lkp <- read_fst('./data/lookups')

# let's subset to London
bnd.l <- subset(bnd, bnd$MSOA %in% lkp[`Region name` == 'London', `MSOA code`])

# quick plot using R core
plot(bnd.l)

# again using leaflet
leaflet() %>% addTiles() %>% addPolygons(data = bnd.l)

# adding labels with the areas names
leaflet() %>% 
    addTiles() %>% 
    addPolygons(
        data = bnd.y, 
        color = 'black',
        weight = 2,
        fillColor = ~pal(IMD),
        fillOpacity = 0.8,
        label = ~MSOAn
    )


leaflet() %>% addTiles() %>% addPolygons(data = bnd.y,  label = ~MSOAn)

# well, you've got the idea ;-) let's now build a more complete "basemap" as a template



rgn1 <- 'London'
msr1 <- y[RGNn == rgn1, .(MSOA, MSOAn, population, IMD)]
bnd1 <- subset(bnd, bnd$MSOA %in% msr1$MSOA)
pal1 <- colorNumeric('Reds', bnd1$IMD)
bnd1 <- merge(bnd1, msr1, 'MSOA')
mp1 <- leaflet() %>% 
    addTiles() %>% 
    addPolygons(
        data = bnd1, 
        color = 'black',
        weight = 2,
        fillColor = ~pal(IMD),
        fillOpacity = 0.8,
        label = ~MSOAn
    )

rgn2 <- 'East of England'
msr2 <- y[RGNn == rgn2, .(MSOA, MSOAn, population, IMD)]
bnd2 <- subset(bnd, bnd$MSOA %in% msr2$MSOA)
pal2 <- colorNumeric('Reds', bnd2$IMD)
bnd2 <- merge(bnd2, msr2, 'MSOA')
mp2 <- leaflet() %>% 
    addTiles() %>% 
    addPolygons(
        data = bnd2, 
        color = 'black',
        weight = 2,
        fillColor = ~pal(IMD),
        fillOpacity = 0.8,
        label = ~MSOAn
    )

leafsync::sync(mp1, mp2)
