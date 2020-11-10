#############################
# GIS DAY 2020 * DATA COVID #
#############################

# load packages
pkgs <- c('data.table', 'leaflet', 'leaflet.extras')
lapply(pkgs, require, char = TRUE)

### Data

# Weekly Cases by MSOA
download.file('https://coronavirus.data.gov.uk/downloads/msoa_data/MSOAs_latest.csv', './download/cases_MSOA.csv')
ycm <- fread('./download/cases_MSOA.csv')

# Daily Cases by LTLA
download.file('https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv', './download/cases_LTLA.csv')

# Daily Cases by age class and UTLA
download.file('https://coronavirus.data.gov.uk/downloads/demographic/cases/specimenDate_ageDemographic-stacked.csv', './download/cases_age.csv')
ycl <- readr::read_csv('./download/cases_LTLA.csv')

# Daily Deaths by Trust
download.file('', './download/deaths_trusts.csv')

# Daily NHS Calls by CCG
download.file('', './download/calls.csv')

