####################################
# CoViD-19 UK * Single leaflet map #
####################################

# load libraries
pkg <- c('data.table', 'fst', 'ggplot2', 'gridExtra', 'htmltools', 'htmlwidgets', 'leaflet', 'leaflet.extras', 'leafpop', 'sp')
invisible(lapply(pkg, require, char = TRUE))

# set constants
data_path <- file.path(pub_path, 'datasets', 'shiny_apps', 'uk_covid')
app_path <- '/srv/shiny-server/uk_covid/'
r_min <- 10
r_max <- 75
build_images <- FALSE

# define functions
add_label_poly <- function(y, type){
    lapply(
        1:nrow(y),
        function(x)
            HTML(
                switch(type,
                    'l' = paste0(
                            '<hr>',
                                '<b>LTLA</b>: ', y$LTLA_name[x], '<br>',
                                '<b>Region</b>: ', y$RGN_name[x], '<br>',
                            '<hr>',
                                '<b>Total Cases</b>: ', format(y$cases[x], big.mark = ','), '<br>',
                                '<b>Cases over 1mln population</b>: ', format(y$pcases[x], big.mark = ','), 
                                    ' (', get_num_sfx(round(sum(y$pcases <= y$pcases[x]) / length(y$pcases) * 100)), ' Q)<br>',
                                '<b>14-day % change</b>: ', format(y$wow[x], big.mark = ','), '% (', y$w0[x], ' vs ', y$w1[x] ,')<br>',
                            '<hr>'
                    ),
                    'u' = paste0(
                            '<hr>',
                                '<b>UTLA</b>: ', y$UTLA_name[x], '<br>',
                                '<b>Region</b>: ', y$RGN_name[x], '<br>',
                            '<hr>',
                                '<b>Total Cases</b>: ', format(y$cases[x], big.mark = ','), '<br>',
                                '<b>Cases over 1mln population</b>: ', format(y$pcases[x], big.mark = ','), 
                                    ' (', get_num_sfx(round(sum(y$pcases <= y$pcases[x]) / length(y$pcases) * 100)), ' Q)<br>',
                                '<b>14-day % change</b>: ', format(y$wow[x], big.mark = ','), '% (', y$w0[x], ' vs ', y$w1[x] ,')<br>',
                            '<hr>'
                    ),
                    's' = paste0(
                            '<hr>',
                                '<b>STP</b>: ', y$STP_name[x], '<br>',
                                '<b>NHS Region</b>: ', y$NHSR_name[x], '<br>',
                            '<hr>',
                                '<b>Total Deaths</b>: ', format(y$deaths[x], big.mark = ','), '<br>',
                                '<b>Deaths over 1mln population</b>: ', format(y$pdeaths[x], big.mark = ','), 
                                    ' (', get_num_sfx(round(sum(y$pdeaths <= y$pdeaths[x]) / length(y$pdeaths) * 100)), ' Q)<br>',
                                # '<b>14-day % change</b>: ', format(y$wchange[x], big.mark = ','), '%<br>',
                            '<hr>'
                    ),
                    't' = paste0(
                            '<hr>',
                                '<b>', ifelse(y$type[x] == 'P', 'Partner', 
                                            ifelse(y$type[x] == 'T', 'Trust', 'Foundation Trust')), 
                                                '</b>: ', y$name[x], '<br>',
                                '<b>CCG</b>: ', y$CCG_name[x], '<br>',
                                '<b>STP</b>: ', y$STP_name[x], '<br>',
                                '<b>NHS Region</b>: ', y$NHSR_name[x], '<br>',
                            '<hr>',
                                '<b>Total Deaths</b>: ', format(y$deaths[x], big.mark = ','), '<br>',
                                # '<b>14-day % change</b>: ', format(y$wchange[x], big.mark = ','), '%<br>',
                            '<hr>'
                    )
                )
            )
    )
}

# read boundaries
bnd <- readRDS(file.path(data_path, 'boundaries'))

# read trust deaths data
yt <- readRDS(file.path(data_path, 'locations'))
yt <- yt[['trusts']]
dts.t <- read_fst(file.path(data_path, 'trust_data'), as.data.table = TRUE)
yt <- dts.t[is.na(date_reported), .(deaths = sum(N)), .(code = trust)][yt, on = 'code'][is.na(deaths), deaths := 0]
yt[deaths > 0, radius := sqrt(deaths) - 1][, radius := (radius/max(radius, na.rm = TRUE)) * (r_max - r_min) + r_min]
qt <- as.integer(fivenum(yt$deaths))

# read LTLA cases data
dts <- readRDS(file.path(data_path, 'cases'))
dts.l <- dts[['LTLA']]
yl1 <- dts.l[, .(cases = sum(cases)), LTLA]
yl2 <- dts.t[is.na(date_reported)][yt[, .(code, LTLA)], on = c(trust = 'code')][, .(deaths = sum(N, na.rm = TRUE)), LTLA]
yl <- yl2[yl1, on = 'LTLA'][is.na(deaths), deaths := 0]
yl[, fatality_rate := round(100 * deaths / cases, 2)]
dts.l[, date_reported := as.Date(date_reported)]
dts.l[, dback := max(date_reported) - date_reported][, wback := floor(dback / 7) + 1]
yw <- dts.l[, .(w0 = sum(cases)), .(LTLA, wback)][order(LTLA, wback)][, w1 := shift(w0, -2)][, wow := round(100 * (w0 - w1) / w1, 1)][wback == 1, .(LTLA, w0, w1, wow)]
yl <- yw[yl, on = 'LTLA']

# y0 <- dts.l[date_reported %in% seq(max(dts.l$date_reported) - 13, max(dts.l$date_reported) - 7, 1)][, .(N0 = sum(cases)), LTLA]
# y1 <- dts.l[date_reported %in% seq(max(dts.l$date_reported) - 6, max(dts.l$date_reported), 1)][, .(N1 = sum(cases)), LTLA]
# yw <- y0[y1, on = 'LTLA'][, wow := round(100 * (N1 / N0 - 1), 2)]

# augment LTLA boundaries
bnd.ltla <- bnd[['LTLA']]
bnd.ltla <- merge(bnd.ltla, yl, by.x = 'id', by.y = 'LTLA')
bnd.ltla$pcases <- round(bnd.ltla$cases * 1000000 / bnd.ltla$popT)
bnd.ltla$pdeaths <- round(bnd.ltla$deaths * 1000000 / bnd.ltla$popT)

# calculate palettes over cases for LTLA polygons 
pal.lcases <- colorQuantile('BuPu', bnd.ltla$cases, 9)
pal.plcases <- colorQuantile('BuPu', bnd.ltla$pcases, 9)
pal.lwow <- colorNumeric('PiYG', bnd.ltla$wow, 9, reverse = TRUE)

# read UTLA cases data
dts.u <- dts[['UTLA']]
yu1 <- dts.u[, .(cases = sum(cases)), UTLA]
yu2 <- dts.t[is.na(date_reported)][yt[, .(code, UTLA)], on = c(trust = 'code')][, .(deaths = sum(N, na.rm = TRUE)), UTLA]
yu <- yu2[yu1, on = 'UTLA'][is.na(deaths), deaths := 0]
yu[, fatality_rate := round(100 * deaths / cases, 2)]

dts.u[, date_reported := as.Date(date_reported)]
dts.u[, dback := max(date_reported) - date_reported][, wback := floor(dback / 7) + 1]
yw <- dts.u[, .(w0 = sum(cases)), .(UTLA, wback)][order(UTLA, wback)][, w1 := shift(w0, -2)][, wow := round(100 * (w0 - w1) / w1, 1)][wback == 1, .(UTLA, w0, w1, wow)]
yu <- yw[yu, on = 'UTLA']

# augment UTLA boundaries
bnd.utla <- bnd[['UTLA']]
bnd.utla <- merge(bnd.utla, yu, by.x = 'id', by.y = 'UTLA')
bnd.utla$pcases <- round(bnd.utla$cases * 1000000 / bnd.utla$popT)
bnd.utla$pdeaths <- round(bnd.utla$deaths * 1000000 / bnd.utla$popT)

# calculate palettes over cases for UTLA polygons 
pal.ucases <- colorQuantile('BuPu', bnd.utla$cases, 9)
pal.pucases <- colorQuantile('BuPu', bnd.utla$pcases, 9)
pal.uwow <- colorNumeric('PiYG', bnd.utla$wow, 9, reverse = TRUE)

# augment STP boundaries
bnd.stp <- bnd[['STP']]
ys <- dts.t[is.na(date_reported)][yt[, .(code, STP)], on = c(trust = 'code')][, .(deaths = sum(N, na.rm = TRUE)), STP]
bnd.stp <- merge(bnd.stp, ys, by.x = 'id', by.y = 'STP')
bnd.stp$pdeaths <- round(bnd.stp$deaths * 1000000 / bnd.stp$popT)

# calculate palettes over deaths for STP polygons 
pal.deaths <- colorQuantile('YlOrRd', bnd.stp$deaths, 9)
pal.pdeaths <- colorQuantile('YlOrRd', bnd.stp$pdeaths, 9)

### create plots (save in subfolder "plots")

if(build_images){
    ## A) UTLA
    
    
    ## B) STP
    
    
    ## C) TRUSTS
    
    for(idx in 1:nrow(yt)){
        
        trs <- yt[idx, code]
        message('Processing trust ', trs, ' (', idx, ' out of ', nrow(yt), ')')
        
        if(yt[idx, deaths] > 0){
            
            # cumulative deaths as line on left axis + daily deaths as bars on right axis
            dt <- dts.t[is.na(date_reported) & trust == trs, .(date_happened, N)][order(date_happened)][, CN := cumsum(N)][CN > 0]
            dt[, lbl := N][N <= 1, lbl := NA]
            gp1 <- ggplot(dt, aes(date_happened)) +
                        geom_col(aes(y = N), fill = 'red') +
                        geom_text(aes(y = lbl, label = N), vjust = 1.4, color = 'black', size = 3) +
                        geom_line(aes(y = CN, group = 1), color = 'blue') +
                        geom_text(aes(y = CN, label = CN), hjust = 0.8, vjust = -1, color = 'blue', size = 2.5) +
                        labs(title = 'Cumulative and Daily Deaths by Date of Death', x = '', y = '') +
                        theme_minimal()
            
            # histogram for reporting delay
            dt <- dts.t[!is.na(date_reported) & !is.na(delay) & trust == trs][, .N, delay]
            gp2 <- ggplot(dt, aes(delay, N)) +
                        geom_col(colour = 'black', fill = 'white') +
                        labs(title = 'Delay in Days between Death and Report', x = '', y = '') +
                        theme_minimal()
            
            # save plot as image
            ggsave(file.path(app_path, 'plots', paste0('trust_', trs, '.png')), grid.arrange(gp1, gp2, nrow = 2), 'png', width = 31.75, height = 20.11, units = 'cm')
            
        }
    
    }

}

# base layer
mp <- leaflet(options = leafletOptions(minZoom = 6)) %>% 
        # addProviderTiles(providers$Esri.WorldTopoMap) %>% 
        addProviderTiles(providers$CartoDB.Positron) %>% 
        addResetMapButton() 

# round choices (LTLA): 1) clear map
mp <- mp %>% 
    addPolygons(
        data = bnd.ltla,
        group = 'LTLA Clear',
        fillOpacity = 0,
        color = 'blue',
        weight = 0.8,
        smoothFactor = 0.2,
#        highlightOptions = hlt.options,
        label = add_label_poly(bnd.ltla, 'l'),
        labelOptions = lbl.options
    )

# round choices (LTLA): 2) cases map
mp <- mp %>% 
    addPolygons(
        data = bnd.ltla,
        group = 'LTLA Cases',
        fillColor = ~pal.lcases(cases),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.ltla, 'l'),
        labelOptions = lbl.options
    ) 

# round choices (LTLA): 3) 1 mln pop cases map
mp <- mp %>% 
    addPolygons(
        data = bnd.ltla,
        group = 'LTLA Cases vs 1mln Population',
        fillColor = ~pal.plcases(pcases),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.ltla, 'l'),
        labelOptions = lbl.options
    )

# round choices (LTLA): 4) variation Week-On-Week
mp <- mp %>% 
    addPolygons(
        data = bnd.ltla,
        group = 'LTLA Cases 14-day Change',
        fillColor = ~pal.lwow(wow),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.ltla, 'l'),
        labelOptions = lbl.options
    )

# round choices (UTLA): 1) clear map
mp <- mp %>% 
    addPolygons(
        data = bnd.utla,
        group = 'UTLA Clear',
        fillOpacity = 0,
        color = 'blue',
        weight = 0.8,
        smoothFactor = 0.2,
#        highlightOptions = hlt.options,
        label = add_label_poly(bnd.utla, 'u'),
        labelOptions = lbl.options
    )

# round choices (UTLA): 2) cases map
mp <- mp %>% 
    addPolygons(
        data = bnd.utla,
        group = 'UTLA Cases',
        fillColor = ~pal.ucases(cases),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.utla, 'u'),
        labelOptions = lbl.options
    ) 
    # ) %>% 
    # addLegend( 
    #     data = bnd.utla,
    #     group = 'UTLA Cases',
    #     pal = pal.ucases, 
    #     values = ~cases, 
    #     opacity = 0.9, 
    #     title = 'CoViD19 Cases by UTLA', 
    #     position = 'bottomright'
    # )

# round choices (UTLA): 3) 1 mln pop cases map
mp <- mp %>% 
    addPolygons(
        data = bnd.utla,
        group = 'UTLA Cases vs 1mln Population',
        fillColor = ~pal.pucases(pcases),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.utla, 'u'),
        labelOptions = lbl.options
    )

# round choices (UTLA): 4) variation Week-On-Week
mp <- mp %>% 
    addPolygons(
        data = bnd.utla,
        group = 'UTLA Cases 14-day Change',
        fillColor = ~pal.uwow(wow),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.utla, 'u'),
        labelOptions = lbl.options
    )

# round choices (STP): 1) clear map
mp <- mp %>% 
    addPolygons(
        data = bnd.stp,
        group = 'STP Clear',
        fillOpacity = 0,
        color = 'red',
        weight = 0.8,
        smoothFactor = 0.2,
#        highlightOptions = hlt.options,
        label = add_label_poly(bnd.stp, 's'),
        labelOptions = lbl.options
    )

# round choices (STP): 2) death map
mp <- mp %>% 
    addPolygons(
        data = bnd.stp,
        group = 'STP Deaths',
        fillColor = ~pal.deaths(deaths),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.stp, 's'),
        labelOptions = lbl.options
    )

# round choices (STP): 3) 1 mln pop deaths map
mp <- mp %>% 
    addPolygons(
        data = bnd.stp,
        group = 'STP Deaths vs 1mln Population',
        fillColor = ~pal.pdeaths(pdeaths),
        fillOpacity = 0.7,
        color = 'gray',
        weight = 0.4,
        smoothFactor = 0.2,
        highlightOptions = hlt.options,
        label = add_label_poly(bnd.stp, 's'),
        labelOptions = lbl.options
    )

# check choices (TRUSTS): 1) no deaths (green, all same size)
yt0 <- yt[deaths == 0]
grp.y0 <- paste0('NHS Trusts No Deaths (', nrow(yt0), ')')
mp <- mp %>% 
    addCircleMarkers(
        data = yt0,
        group = grp.y0,
        lng = ~x_lon, lat = ~y_lat,
        color = 'black', 
        weight = 1,
        radius = 6,
        fillColor = 'green', 
        fillOpacity = 0.6,
        label = add_label_poly(yt0, 't'),
        labelOptions = lbl.options
    )

# check choices (TRUSTS): 2) death less than or equal to Q1 (#FCC5C0)
yt1 <- yt[deaths > 0 & deaths <= qt[2]]
grp.y1 <- paste0('Hospitals Deaths Less Than or Equal to Q1 = ', qt[2], ' (', nrow(yt1), ')')
mp <- mp %>% 
    addCircleMarkers(
        data = yt1,
        group = grp.y1,
        lng = ~x_lon, lat = ~y_lat,
        radius = ~radius,
        fillColor = '#FCC5C0', 
        fillOpacity = 0.6,
        weight = 1,
        color = 'black',
        label = add_label_poly(yt1, 't'),
        labelOptions = lbl.options,
        popup = ~popupImage(paste0('/srv/shiny-server/uk_covid/plots/trust_', code, '.png'), src = 'local')
)

# check choices (TRUSTS): 3) death between Q1 + 1 and Q2 = Med (#F768A1)
yt2 <- yt[deaths > qt[2] & deaths <= qt[3]]
grp.y2 <- paste0('Hospitals Deaths Between (Q1 + 1) = ', (qt[2] + 1), ' and Md = ', qt[3], ' (', nrow(yt2), ')')
mp <- mp %>% 
    addCircleMarkers(
        data = yt2,
        group = grp.y2,
        lng = ~x_lon, lat = ~y_lat,
        radius = ~radius,
        fillColor = '#F768A1', 
        fillOpacity = 0.6,
        weight = 1,
        color = 'black', 
        label = add_label_poly(yt2, 't'),
        labelOptions = lbl.options,
        popup = ~popupImage(paste0('/srv/shiny-server/uk_covid/plots/trust_', code, '.png'), src = 'local')
    )

# check choices (TRUSTS): 4) death between Med + 1 and Q3 (#DD3497)
yt3 <- yt[deaths > qt[3] & deaths <= qt[4]]
grp.y3 <- paste0('Hospitals Deaths Between (Md + 1) = ', (qt[3] + 1), ' and Q3 = ', qt[4], ' (', nrow(yt3), ')')
mp <- mp %>% 
    addCircleMarkers(
        data = yt3,
        group = grp.y3,
        lng = ~x_lon, lat = ~y_lat,
        radius = ~radius,
        fillColor = '#DD3497', 
        fillOpacity = 0.6,
        weight = 1,
        color = 'black', 
        label = add_label_poly(yt3, 't'),
        labelOptions = lbl.options,
        popup = ~popupImage(paste0('/srv/shiny-server/uk_covid/plots/trust_', code, '.png'), src = 'local')
    )

# check choices (TRUSTS): 5) death greater than Q3 + 1 (#7A0177)
yt4 <- yt[deaths > qt[4]]
grp.y4 <- paste0('Hospitals Deaths More Than (Q3 + 1) = ', (qt[4] + 1), ' (', nrow(yt4), ')')
mp <- mp %>% 
    addCircleMarkers(
        data = yt4,
        group = grp.y4,
        lng = ~x_lon, lat = ~y_lat,
        radius = ~radius,
        fillColor = '#7A0177', 
        fillOpacity = 0.6,
        weight = 1,
        color = 'black', 
        label = add_label_poly(yt4, 't'),
        labelOptions = lbl.options,
        popup = ~popupImage(paste0('/srv/shiny-server/uk_covid/plots/trust_', code, '.png'), src = 'local')
    )

# Add upper right menu for controls
mp <- mp %>% 
    addLayersControl(
    	baseGroups = c(
    	    'LTLA Clear', 'LTLA Cases', 'LTLA Cases vs 1mln Population', 'LTLA Cases 14-day Change',
    	    'UTLA Clear', 'UTLA Cases', 'UTLA Cases vs 1mln Population', 'UTLA Cases 14-day Change',
    	    'STP Clear', 'STP Deaths', 'STP Deaths vs 1mln Population'
    	),
        overlayGroups = c(grp.y0, grp.y1, grp.y2, grp.y3, grp.y4),
    	options = layersControlOptions(collapsed = FALSE)
    ) 

# Add title
mp <- mp %>% 
        addControl(
            tags$div(HTML(paste0(
                '<p style="font-size:20px;padding:10px 5px 10px 10px;margin:0px;background-color:#FFD5C6;">',
                    'NHS England CoViD-19:', '<br> - Cases by LTLA, UTLA, and STP<br> - Deaths by Hospital', '<br><br>',
                    'Last Report Date: ', format(max(dts.l$date_reported, na.rm=TRUE), '%d %B'),
                '</p>'
            ))),
            position = 'bottomleft'
        )

# Fix the default
mp <- mp %>% 
        hideGroup(c(grp.y0, grp.y1, grp.y2, grp.y3, grp.y4)) %>% 
        showGroup('LTLA Cases vs 1mln Population') %>% showGroup(grp.y4)

# save map as html in shiny server app folder
saveWidget(mp, file.path(app_path, 'index.html'))

# Substitute plot paths in map html file
y <- readLines(file.path(app_path, 'index.html'))
y <- gsub('../graphs', './plots', y)
fc <- file(file.path(app_path, 'index.html'))
writeLines(y, fc)
close(fc)

# clean
rm(list = ls())
gc()
