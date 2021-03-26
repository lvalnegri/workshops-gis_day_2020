###################################
# GIS DAY 2020 * SHINY APP - ui.R #
###################################

fluidPage(

    titlePanel('England Covid-19'),

    sidebarLayout(

        sidebarPanel(

            pickerInput('cbo_mtc', 'METRIC:', mtc.lst, 'wr'),
            tags$br(),
            
            pickerInput('cbo_cls', 'CLASS METHOD:', cls.lst, 'quantile'),
            tags$br(),
            
            pickerInput('cbo_pal', 'PALETTE:', palettes.lst, 'YlOrBr'),
            checkboxInput('chk_pal_rev', 'REVERSE'),
            sliderInput('cbo_pal_bns', 'BINS:', min = 5, max = 13, value = 10),
            tags$br(),
            
            checkboxInput('chk_lgn', 'ADD LEGEND', FALSE),
            checkboxInput('chk_ttl', 'ADD TITLE', FALSE),
            tags$hr(),
            
            HTML(
                '<p>Contains <a href="http://geoportal.statistics.gov.uk/" target="_blank">OS data</a>
                 <p> All content is available under the 
                     <a href="http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/" target="_blank">
                        Open Government Licence v3.0
                     </a></p>
                 <p> &copy; Crown copyright and database right [2020]</p>'
            ),

            width = 3

        ),

        mainPanel(

            tabsetPanel(

                tabPanel('Map', tags$br(), withSpinner(leafletOutput('out_map', height = '600px') ) ),

                tabPanel('Table', tags$br(), textOutput('out_txt'), withSpinner(DTOutput('out_tbl') ) )

            )

        )

    )

)
