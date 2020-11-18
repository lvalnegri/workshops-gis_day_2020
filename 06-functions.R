# load packages -----
pkgs <- c('classInt', 'leaflet', 'leaflet.extras', 'RColorBrewer')
lapply(pkgs, require, char = TRUE)

#' List of background tiles for leaflet maps
tiles.lst <- list(
    'OSM Mapnik' = 'OpenStreetMap.Mapnik',
#    'OSM B&W' = 'OpenStreetMap.BlackAndWhite',
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

#' List of available methods when classifying numeric variables (for package classInt)
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

#' List of ColorBrewer palettes classified by type of visualization scale
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

#' Generic options for labels when hovering polygons in leaflet maps
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

#' Generic options for highlight when hovering polygons in leaflet maps
hlt.options <- highlightOptions(
    weight = 6,
    color = 'white',
    opacity = 1,
    bringToFront = TRUE,
    sendToBack = TRUE
)

#' A leaflet map to start with, centered around a givcen coordinate or fitting a given bounding box
#'
#' @param coords Center the map around this long/lat point (default is UK centroid)
#' @param bbox Alternative to <coords>, set the bounds of a map. In a 2x2 matrix form, long as first row, lat as second row; min as first  column, max as second column
#' @param zm The admissible minimum zoom. Default is 6, which is the minimum for the UK to be visible as a whole
#' @param tiles List of map backgroud tiles, by default all layers listed in tiles.lst. Pass a NULL value to add only the default tile.
#'
#' @return a leaflet map
basemap <- function(coords = c(-2.903205, 54.17463), bbox = NULL, zm = 6, tiles = tiles.lst, bt = NULL){
    mp <- leaflet(options = leafletOptions(minZoom = zm)) %>%
        enableTileCaching() %>%
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
    if(!is.null(bt))
        mp <- mp %>% 
            addPolygons(
                data = bt,
                group = 'bt',
                color = 'brown',
                weight = 2,
                opacity = 0.8,
                smoothFactor = 0.2,
                highlightOptions = hlt.options,
                label = bt[[1]],
                labelOptions = lbl.options
            ) %>% 
            addLayersControl( 
                baseGroups = names(tiles.lst), 
                overlayGroups = 'bt', 
                options = layersControlOptions(collapsed = FALSE) 
            ) 
    
    mp
}
# build a popup (on mouse click) for the dotmap
add_popup_dots <- function(y){
    lapply(
        1:nrow(y),
        function(x){
            HTML(paste0(
                '<b>Trust</b>: ', y$TRSTn[x], '<br>', 
                '<b>Trust Code</b>: ', y$TRST[x], '<br>', 
                '<b>Total Deaths: ', format(y$deaths[x], big.mark = ','), '</b><br><br>', 
                #'<b>Rate vs 100K population</b>: ', format(round(y$distance[x] / 1000, 3), nsmall = 3), ' <br>', 
                '<b>CCG</b>: ', dts[['CCG']][CCG == y$CCG[x], CCGn], '<br>',
                '<b>STP</b>: ', dts[['CCG']][CCG == y$CCG[x], STPn], '<br><br>'
            ))
        }
    )
}

# build the label (on mouse hover) for a choropleth map
add_label_poly <- function(y){
    lapply(
        1:nrow(y),
        function(x){
            y1 <- ...
            y2 <- ...
            HTML(paste(yt1, yt2))
        }
    )
}

# build a popup (on mouse click) for the choropleth map
add_popup_poly <- function(y){
    lapply(
        1:nrow(y),
        function(x){
            HTML(paste0(
                '<b>Trust</b>: ', y$TRSTn[x], '<br>', 
                '<b>Trust Code</b>: ', y$TRST[x], '<br>', 
                '<b>Total Deaths: ', format(y$deaths[x], big.mark = ','), '</b><br><br>', 
                #'<b>Rate vs 100K population</b>: ', format(round(y$distance[x] / 1000, 3), nsmall = 3), ' <br>', 
                '<b>CCG</b>: ', dts[['CCG']][CCG == y$CCG[x], CCGn], '<br>',
                '<b>STP</b>: ', dts[['CCG']][CCG == y$CCG[x], STPn], '<br><br>'
            ))
        }
    )
}

# build a popup table (on mouse click) for the choropleth map
add_tpopup_poly <- function(x, ydbe){
    y <- ydbe[SZN == x]
    yk <- kable(y[, .(desc, val, prop)]) %>%
        kable_styling(
            bootstrap_options = c('striped', 'hover', 'condensed', 'responsive'), 
            font_size = 10, 
            full_width = FALSE
        )
    for(cp in unique(y$cap))
        yk <- yk %>% 
        pack_rows(cp, 
                  min(y[cap == cp, which = TRUE]), 
                  max(y[cap == cp, which = TRUE]),
                  label_row_css = "background-color: #666; color: #fff;"
        )
    if(nrow(y) > 10) yk <- yk %>% scroll_box(height = '300px')
    yk
}

#' Determines labels for (n + 1) bins given a series of n breaks or a convenient building method
#'
#' @param y a vector describing
#' @param beta  <description of beta>
#'
#' @return a data.table with limits and labels
#'
get_fxb_labels <- function(y, dec.fig = 1, del_signs = TRUE){
    y <- gsub('^ *|(?<= ) | *$', '', gsub('(?!\\+|-|\\.)[[:alpha:][:punct:]]', ' ', y, perl = TRUE), perl = TRUE)
    y <- paste(y, collapse = ' ')
    if(del_signs){
        y <- gsub('*\\+', Inf, y)
        y <- gsub('*\\-', -Inf, y)
    }
    y <- unique(sort(as.numeric(unlist(strsplit(y, split = ' ')))))
    lbl_brks <- format(round(y, 3), nsmall = dec.fig)
    lbl_brks <- str_pad(lbl_brks, max(nchar(lbl_brks)), 'left')
    y <- data.table(
        'lim_inf' = lbl_brks[1:(length(lbl_brks) - 1)],
        'lim_sup' = lbl_brks[2:length(lbl_brks)],
        'label' = sapply(1:(length(lbl_brks) - 1), function(x) paste0(lbl_brks[x], ' â”€ ', lbl_brks[x + 1]))
    )
    
}

#' # Determines the text intervals for the colours in the legend to be used in a leaflet thematic map
#'
#' @param alpha <description of alpha>
#' @param beta  <description of beta>
#'
#' @return describe what the function is giving back to the user (insert "None" if there's no value returned)
#'
get_map_legend <- function(mtc, brks, dec.fig = 2, del_signs = TRUE) {
    lbl <- get_fxb_labels(brks, dec.fig, del_signs)
    brks <- sort(as.numeric(unique(c(lbl$lim_inf, lbl$lim_sup))))
    mtc <- data.table('value' = mtc)
    mtc <- mtc[, .N, value][!is.na(value)]
    mtc[, label := cut(value, brks, lbl$label, ordered = TRUE)]
    mtc <- mtc[, .(N = sum(N)), label][order(label)][!is.na(label)]
    mtc <- mtc[lbl[, .(label)], on = 'label'][is.na(N), N := 0]
    mtc[, N := format(N, big.mark = ',')]
    ypad <- max(nchar(as.character(mtc$N))) + 3
    mtc[, label := paste0(label, str_pad(paste0(' (', N, ')'), ypad, 'left'))]
    mtc$label
}

# Returns a set of limits for the breaks, a list of corresponding colours, a text for the legend
get_palette <- function(X,
                        cls_mth = 'quantile',
                        n_brks = 7,
                        fxd_brks = NULL,
                        use_palette = TRUE,
                        br_pal = 'Greys',
                        fxd_cols = c('#ff0000', '#ffff00', '#00ff00'),
                        rev_cols = FALSE,
                        add_legend = TRUE,
                        dec.fig = 0,
                        bsep = ',',
                        del_signs = TRUE
){
    
    if(!cls_mth %in% c('fixed', 'equal', 'quantile', 'pretty', 'jenks', 'hclust', 'kmeans')){
        warning('The provided method does not exist! Reverting to "quantile"')
        cls_mth <- 'quantile'
    }
    
    if(cls_mth == 'fixed'){
        if(is.null(fxd_brks)) stop('When asking for the "fixed" method, you have to include a vector of convenient bin limits.')
        if(!is.numeric(fxd_brks)) stop('The vector containing the bin limits must be numeric.')
        fxd_brks <- sort(fxd_brks)
        mX <- min(X, na.rm = TRUE)
        MX <- max(X, na.rm = TRUE)
        if(MX > max(fxd_brks)) fxd_brks <- c(fxd_brks, MX)
        if(mX < min(fxd_brks)) fxd_brks <- c(mX, fxd_brks)
        n_brks <- length(fxd_brks) - 1
    }
    
    brks_poly <-
        if(cls_mth == 'fixed'){
            classIntervals(X, n = n_brks, style = 'fixed', fixedBreaks = fxd_brks)
        } else {
            classIntervals(X, n = n_brks, style = cls_mth)
        }
    
    # Determine the color palette
    if(use_palette){
        if(!br_pal %in% rownames(brewer.pal.info)){
            warning('The provided palette does not exist! Reverting to "Greys"')
            br_pal <- 'Greys'
        }
        col_codes <-
            if(n_brks > brewer.pal.info[br_pal, 'maxcolors']){
                colorRampPalette(brewer.pal(brewer.pal.info[br_pal, 'maxcolors'], br_pal))(n_brks)
            } else {
                brewer.pal(n_brks, br_pal)
            }
        if(rev_cols) col_codes <- rev(col_codes)
    } else {
        col_codes <- colorRampPalette(fxd_cols)(n_brks)
    }
    
    # return a list
    if(add_legend){
        list(
            findColours(brks_poly, col_codes), brks_poly, col_codes,
            get_map_legend(X, brks_poly$brks, dec.fig, del_signs)
        )
    } else {
        list(findColours(brks_poly, col_codes), brks_poly, col_codes)
    }
}
