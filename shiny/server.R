#######################################
# GIS DAY 2020 * SHINY APP - server.R #
#######################################

server <- function(input, output, session) {

    plt <- reactive({
        if(input$cbo_cls == 'quantile'){
            colorQuantile(input$cbo_pal, bnd@data[, input$cbo_mtc], as.numeric(input$cbo_pal_bns), reverse = input$chk_pal_rev)
        } else {
            colorBin(input$cbo_pal, bnd@data[, input$cbo_mtc], as.numeric(input$cbo_pal_bns), reverse = input$chk_pal_rev)
        }
    })
    
    mp <- reactive({
        basemap() %>%
            addPolygons(
                data = bnd,
                layerId = bnd$LTLA, # ===> this is NEEDED for shape_click to catch the id of the polygon
                fillColor = ~plt()(bnd@data[, input$cbo_mtc]),
                fillOpacity = 0.7,
                color = 'gray',
                weight = 0.4,
                smoothFactor = 0.2,
                highlightOptions = hlt.options,
                label = lapply(1:nrow(bnd), function(x) kableExtra::kable(label_tbl(bnd[x]))), # add_label_poly(bnd),
                labelOptions = lbl.options
            ) %>% 
            addLayersControl( baseGroups = names(tiles.lst) )
    })

    output$out_map <- renderLeaflet({ mp() })
    
    observeEvent(input$chk_lgn, {
        if(input$chk_lgn){
            leafletProxy("out_map") %>% 
                addLegend(
                    data = bnd,
                    layerId = 'lgn',
                    pal = plt(),
                    values = bnd@data[, input$cbo_mtc],
                    opacity = 0.7,
                    title = names(which(mtc.lst == input$cbo_mtc)),
                    position = 'bottomright'
                )
        } else {
            leafletProxy("out_map") %>% removeControl('lgn')
        }
    })    
    
    observeEvent(input$chk_ttl, {
        if(input$chk_ttl){
            leafletProxy("out_map") %>% 
                addControl(
                    layerId = 'ttl',
                    tags$div(HTML(paste0(
                        '<p style="font-size:12px;padding:6px 3px 6px 6px;margin:0px;background-color:#FFD5C6;">',
                            'England CoViD-19 Cases by LTLA <br>',
                            'Last Report: ', format(mxd + 1, '%d %b %Y'), '<br>',
                            'Source: <a href="https://www.gov.uk/government/publications/national-covid-19-surveillance-reports">Public Health England</a>',
                        '</p>'
                    ))),
                    position = 'bottomleft'
                )
        } else {
            leafletProxy("out_map") %>% removeControl('ttl')
        }
    })    
    
    observeEvent(input$out_map_shape_click, {
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
    
    output$out_tbl <- renderDT({ 
        datatable(dts,
            rownames = FALSE,
            selection = 'single',
            class = 'cell-border stripe hover nowrap',
            extensions = c('Buttons', 'FixedColumns', 'Scroller'),
            options = list(
                scrollX = TRUE,
                scrollY = 600,
                scroller = TRUE,
                fixedColumns = list(leftColumns = 2),
                searchHighlight = TRUE,
                deferRender = TRUE,
                columnDefs = list( list(targets = c(0, 2, 4, 6), visible = FALSE) ),
                initComplete = JS(
                    "function(settings, json) {",
                    "$(this.api().table().header()).css({'background-color': '#238443', 'color': '#fff'});",
                    "}"
                ),
                dom = 'Bftip'
            )
        ) %>% 
        formatCurrency(c('area', 'population', 'tc', 'wc', 'pc', 'fc', 'bc', 'tr', 'wr', 'pr', 'fr', 'br'), '', digits = 0) %>% 
        formatPercentage(c('wpr', 'wfr', 'fbr'), digits = 1) %>%
        formatStyle('wc',
           background = styleColorBar(dts[, wc], '#c6dbef'),
           backgroundSize = '100% 90%',
           backgroundRepeat = 'no-repeat',
           backgroundPosition = 'center'
        ) 
            
    })

}
