#######################################
# GIS DAY 2020 * SHINY APP - server.R #
#######################################

server <- function(input, output, session) {

    mp <- reactive({
        
        pal <- colorBin(input$cbo_pal, bnd@data[, input$cbo_mtc], as.numeric(input$cbo_pal_bns), reverse = input$chk_pal_rev)
        y <- basemap() %>%
                addPolygons(
                    data = bnd,
                    layerId = bnd$LTLA, # ===> this is NEEDED for shape_click to catch the id of the polygon
                    fillColor = ~pal(bnd@data[, input$cbo_mtc]),
                    fillOpacity = 0.7,
                    color = 'gray',
                    weight = 0.4,
                    smoothFactor = 0.2,
                    highlightOptions = hlt.options,
                    label = ~LTLAn, # add_label_poly(bnd),
                    labelOptions = lbl.options
                ) %>% 
                addLayersControl(baseGroups = names(tiles.lst))
        
        if(input$chk_lgn)
            y <- y %>% 
                addLegend(
                    data = bnd,
                    pal = pal,
                    values = bnd@data[, input$cbo_mtc],
                    opacity = 0.7,
                    title = names(which(mtc.lst == input$cbo_mtc)),
                    position = 'bottomright'
                )
        
        if(input$chk_ttl)
            y <- y %>% 
                addControl(
                    tags$div(HTML(paste0(
                        '<p style="font-size:12px;padding:6px 3px 6px 6px;margin:0px;background-color:#FFD5C6;">',
                            'England CoViD-19 Cases Rates by LTLA <br>',
                            'Last Report: ', format(mxd + 1, '%d %b %Y'), '<br>',
                            'Source: <a href="https://www.gov.uk/government/publications/national-covid-19-surveillance-reports">Public Health England</a>',
                        '</p>'
                    ))),
                    position = 'bottomleft'
                )
    
        y
        
    })

output$out_map <- renderLeaflet({ mp() })

# show popup on click
observeEvent(input$out_map_shape_click, {
    p <- input$out_map_shape_click
    print(p)
    showModal(
        modalDialog(
            renderDygraph( add_popup_poly(input$out_map_shape_click$id) ),
            title = paste('LTLA:', dts[LTLA == input$out_map_shape_click$id, LTLAn]),
            size = 'm',
            footer = NULL,
            easyClose = TRUE
        )
    )
})

output$out_tbl <- renderDT({ datatable(dts) })

# save map as html in shiny server app folder
# saveWidget(mp, 'ltla.html')

}
