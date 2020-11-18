#######################################
# GIS DAY 2020 * SHINY APP - global.R #
#######################################

# this line must be deleted if the app is deployed on a server
# setwd('./shiny/')

# load packages
pkgs <- c(
    'data.table', 'DT', 'dygraphs', 'fst', 'htmltools', 'leaflet', 'RColorBrewer', 'sp',
    'leaflet.extras', 'leaflet.extras2', 'leaflet.minicharts', 'leafpop', 'leafsync',
    'shiny', 'shinycssloaders', 'shinyjs', 'shinyWidgets'
)
lapply(pkgs, require, char = TRUE)

# set options 
options(spinner.color = '#333399', spinner.size = 1, spinner.type = 4)
options(bitmapType = 'cairo', shiny.usecairo = TRUE)
options(warn = -1)

# load data
bnd <- readRDS('../boundaries/LTLA')
dts <- readRDS('../data/datasets')
dts <- dts[['LTLA']]
bnd <- merge(bnd, dts, 'LTLA')
cvd <- read_fst('../covid/cases_ltla', as.data.table = TRUE)
mxd <- max(cvd$day)

# list of metric to be displayed on choropleth
mtc.lst <- c(
    'Total Cases' = 'tc', 'Total Rate' = 'tr', 
    'Cases Last 7 days' = 'wc', 'Rate Last 7 days' = 'wr',
    'Var 7 days' = 'wpr', 'Var 14 days' = 'fbr'
)

# list of background tiles
tiles.lst <- list(
    'OSM Mapnik' = 'OpenStreetMap.Mapnik',
    'OSM HOT' = 'OpenStreetMap.HOT',
    'OSM Topo' = 'OpenTopoMap',
    'Stamen Toner' = 'Stamen.Toner',
    'Stamen Toner Lite' = 'Stamen.TonerLite',
    'Stamen Terrain' = 'Stamen.Terrain',
    'Stamen Watercolor' = 'Stamen.Watercolor',
    'Esri Street Map' = 'Esri.WorldStreetMap',
    'Esri Topo Map' = 'Esri.WorldTopoMap',
    'Esri Imagery' = 'Esri.WorldImagery',
    'CartoDB Positron' = 'CartoDB.Positron',
    'CartoDB Dark Matter' = 'CartoDB.DarkMatter',
    'Hike Bike' = 'HikeBike.HikeBike'
)

# list of available methods when classifying numeric variables (for package classInt)
class.methods <- c(
    'Quantiles' = 'quantile',           # each class contains (more or less) the same amount of values
    'Equal Intervals' = 'equal',        # the range of the variable is divided into n part of equal space
    'Fixed' = 'fixed',                  # need an additional argument fixedBreaks that lists the n+1 values to be used
    'Pretty Integers' = 'pretty',       # sequence of about n+1 equally spaced round values which cover the range of the values in x. 
                                        # the values are chosen so that they are 1, 2 or 5 times a power of 10.
    'Natural Breaks' = 'jenks',         # seeks to reduce the variance within classes and maximize the variance between classes
    'Hierarchical Cluster' = 'hclust',  # clustering with short distance
    'K-means Cluster' = 'kmeans'        # clustering with low variance and similar size
)

# list of ColorBrewer palettes classified by type of visualization scale
palettes.lst <- list(
    'SEQUENTIAL' = c(  # ordinal data where (usually) low is less important and high is more important
        'Blues' = 'Blues', 'Blue-Green' = 'BuGn', 'Blue-Purple' = 'BuPu', 'Green-Blue' = 'GnBu', 'Greens' = 'Greens', 'Greys' = 'Greys',
        'Oranges' = 'Oranges', 'Orange-Red' = 'OrRd', 'Purple-Blue' = 'PuBu', 'Purple-Blue-Green' = 'PuBuGn', 'Purple-Red' = 'PuRd', 'Purples' = 'Purples',
        'Red-Purple' = 'RdPu', 'Reds' = 'Reds', 'Yellow-Green' = 'YlGn', 'Yellow-Green-Blue' = 'YlGnBu', 'Yellow-Orange-Brown' = 'YlOrBr',
        'Yellow-Orange-Red' = 'YlOrRd'
    ),
    'DIVERGING' = c(   # ordinal data where both low and high are important (i.e. deviation from some reference "average" point)
        'Brown-Blue-Green' = 'BrBG', 'Pink-Blue-Green' = 'PiYG', 'Purple-Red-Green' = 'PRGn', 'Orange-Purple' = 'PuOr', 'Red-Blue' = 'RdBu', 'Red-Grey' = 'RdGy',
        'Red-Yellow-Blue' = 'RdYlBu', 'Red-Yellow-Green' = 'RdYlGn', 'Spectral' = 'Spectral'
    ),
    'QUALITATIVE' = c( # categorical/nominal data where there is no logical order
        'Accent' = 'Accent', 'Dark2' = 'Dark2', 'Paired' = 'Paired', 'Pastel1' = 'Pastel1', 'Pastel2' = 'Pastel2',
        'Set1' = 'Set1', 'Set2' = 'Set2', 'Set3' = 'Set3'
    )
)

# options for labels when hovering polygons
lbl.options <- labelOptions(
    nohide = TRUE,
    textsize = '12px',
    direction = 'right',
    sticky = FALSE,
    opacity = 0.8,
    offset = c(10, -10),
    style = list(
        'color' = 'black',
        'border-color' = 'rgba(0,0,0,0.5)',
        'font-family' = 'verdana',
        'font-style' = 'normal',
        'font-size' = '14px',
        'font-weight' = 'normal',
        'padding' = '2px 6px',
        'box-shadow' = '3px 3px rgba(0,0,0,0.25)'
    )
)

# options for highlight when hovering polygons
hlt.options <- highlightOptions(
    weight = 6,
    color = 'white',
    opacity = 1,
    bringToFront = TRUE,
    sendToBack = TRUE
)

# the starting map
basemap <- function(coords = c(-2.903205, 54.17463), bbox = NULL, zm = 6, tiles = tiles.lst){
    mp <- leaflet(options = leafletOptions(minZoom = zm)) %>%
        enableTileCaching() %>%
        addEasyprint() %>% 
        addSearchOSM() %>%
        addResetMapButton() %>%
        addFullscreenControl()
    if(is.null(bbox)){
        mp <- mp %>% setView(coords[1], coords[2], zoom = zm)
    } else {
        mp <- mp %>% fitBounds(bbox[1, 1], bbox[2, 1], bbox[1, 2], bbox[2, 2])
    }
    if(is.null(tiles)){
        mp <- mp %>% addTiles()
    } else {
        for(idx in 1:length(tiles))
            mp <- mp %>%
                addProviderTiles(tiles[[idx]], group = names(tiles)[idx]) %>%
                showGroup(tiles[1])
    }
    mp
}

# build the label (on mouse hover)
add_label_poly <- function(y){
    lapply(
        1:nrow(y),
        function(x)
            HTML(
                '<hr>',
                    '<b>LTLA</b>: ', y$UTLAn[x], '<br>',
                    '<b>Region</b>: ', y$RGNn[x], '<br>',
                '<hr>',
                    '<b>Total Cases</b>: ', y$tc[x], '<br>',
                    '<b>Total Rate</b>: ', y$tr[x], '<br><br>',
                    '<b>Weekly Cases</b>: ', y$wc[x], '<br>',
                    '<b>Weekly Rate</b>: ', y$wr[x], '<br>',
                    '<b>Weekly Change</b>: ', y$wpr[x], '<br><br>',
                    '<b>Fortnight Cases</b>: ', y$fc[x], '<br>',
                    '<b>Fortnight Rate</b>: ', y$fr[x], '<br>',
                    '<b>Fortnight Change</b>: ', y$fbr[x], '<br><br>',
                '<hr>',
                    '<b>Population</b>: ', format(y$population[x], big.mark = ','), '<br>',
                    '<b>Density</b>: ', format(round(y$population[x]/y$area[x]), big.mark = ','),
                '<hr>'
            )
    )
}

# build the popup (on mouse click)
add_popup_poly <- function(x){
    y <- cvd[LTLA == x, .(day, cases)]
    dygraph(y) %>% 
        dyLegend(width = 100, show = "always", hideOnMouseOut = FALSE) %>% 
        dyAxis('y', label = 'Total', drawGrid = TRUE) %>%
        dyHighlight( highlightCircleSize = 4, highlightSeriesBackgroundAlpha = 0.4, hideOnMouseOut = TRUE, highlightSeriesOpts = list(strokeWidth = 2) ) %>% 
        dyRangeSelector( dateWindow = c(mxd - 61, mxd - 2), height = 30, strokeColor = 'black' ) %>%
        dyRoller(rollPeriod = 7) %>%
        dyOptions( axisLineWidth = 1.25, stackedGraph = FALSE, fillGraph = FALSE) 
}
