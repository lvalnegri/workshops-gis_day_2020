###################################
# GIS DAY 2020 * INSTALL PACKAGES #
###################################
# Notice that these are MORE packages than the one needed for the workshop

pkgs <- c(
    # data collection and wrangling 
    'data.table', 'fst', 'dplyr', 'openxlsx', 'readxl', 'tidyr',
    # data display
    'DT', 'formattable', 'rhandsontable', 'rpivotTable', 
    'flextable', 'htmlTable', 'knitr', 'kableExtra', 'huxtable', 'pixiedust', 'basictabler',
    # data visualization
    'ggplot2', 'ggiraph', 'ggthemes',
    'htmlwidgets', 'leaflet', 'leaflet.extras', 'leaflet.extras2', 'leafsync', 'rbokeh',
     'classInt', 'scales', 'paletteer',
    # data presentation / deployment
    'htmltools', 'rmarkdown', 'shiny', 'shinyjs', 'shinyscreenshot', 'shinyWidgets',
    # spatial tools
    'ggmap', 'ggspatial', 'maptools', 'mapview', 'raster', 'rgdal', 'rgeos', 'rmapshaper', 'sf', 'sp', 'tmap'
)
pkgs.not <- pkgs[!sapply(pkgs, require, char = TRUE)]
if(length(pkgs.not) > 0) install.packages(pkgs.not)
lapply(pkgs, require, char = TRUE)
