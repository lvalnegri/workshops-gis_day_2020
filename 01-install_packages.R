###################################
# GIS DAY 2020 * INSTALL PACKAGES #
###################################
# Notice that these are MORE packages than the ones needed for the workshop

pkgs <- c(
    # data collection and wrangling 
    'data.table', 'fst', 'dplyr', 'openxlsx', 'readxl', 'tidyr',
    # data display
    'DT', 'formattable', 'lineupjs', 'pivta', ' reactable', 'rhandsontable', 'rpivotTable', 
     'basictabler', 'flextable', 'gt', 'htmlTable', 'knitr', 'kableExtra', 'huxtable', 'pixiedust',
    # data visualization
    'ggplot2', 'ggiraph', 'ggmap', 'ggthemes', 'htmlwidgets', 'rbokeh',
     'classInt', 'scales', 'paletteer',
    # data presentation / deployment
    'htmltools', 'rmarkdown', 'shiny', 'shinyjs', 'shinyscreenshot', 'shinyWidgets', 'xaringan',
    # spatial tools
    'ggmap', 'ggspatial', 'leaflet', 'leaflet.extras', 'leaflet.extras2', 'leafpop', 'leafsync', 
    'maptools', 'mapview', 'raster', 'rgdal', 'rgeos', 'rmapshaper', 'sf', 'sp', 'tmap'
)
pkgs.not <- pkgs[!sapply(pkgs, require, char = TRUE)]
if(length(pkgs.not) > 0) install.packages(pkgs.not)
lapply(pkgs, require, char = TRUE)
