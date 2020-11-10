##################################
# GIS DAY 2020 * DATA COLLECTION #
##################################

# load packages -----
pkgs <- c('data.table', 'fst', 'openxlsx', 'readxl', 'rgdal')
lapply(pkgs, require, char = TRUE)

# define function -----
dunzip <- function(url, fname, pref = NA){ 
  download.file(url, 'temp.zip')
  unzip('temp.zip')
  if(is.na(pref)){
    file.rename(unzip('temp.zip', list = TRUE)$Name, paste0('./download/', fname))
  } else {
    fnames <- list.files('./', paste0(pref, '*.*'))
    file.rename(fnames, file.path('./boundaries', gsub('.*\\.', paste0(fname, '.'), fnames)))
  }
  file.remove('temp.zip')
}

### Ancillary files -----

## MSOA <=> LTLA <=> RGN lookups table
download.file('https://coronavirus.data.gov.uk/downloads/supplements/lookup_table.csv', './download/lookups.csv')
y <- fread('./download/lookups.csv', select = 1:7, col.names = c('RGN', 'RGNn', 'UTLA', 'UTLAn', 'LTLA', 'LTLAn', 'MSOA'))
write_fst(y, './data/lookups')

## MSOA HoC Names (it is actually already included in the above file, but some names have been added wrong)
download.file('https://visual.parliament.uk/msoanames/static/MSOA-Names-1.7.csv', './download/msoa_names.csv')
y <- fread('./download/msoa_names.csv', select = c('msoa11cd', 'msoa11hclnm'), col.names = c('MSOA', 'MSOAn'))
write_fst(y, './data/msoa_names')

## Lookups Census Small Areas OA => LSOA => MSOA
download.file('https://opendata.arcgis.com/datasets/6ecda95a83304543bc8feedbd1a58303_0.csv', './download/oas.csv')
y <- fread('./download/oas.csv', select = c('OA11CD', 'LSOA11CD', 'MSOA11CD'), col.names = c('OA', 'LSOA', 'MSOA'))
write_fst(y, './data/oa_lsoa_msoa')
write_fst(unique(y[, OA := NULL]), './data/lsoa_msoa')

### Geodemographics -----

## Population (mid-2019)
dunzip('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fmiddlesuperoutputareamidyearpopulationestimates%2fmid2019sape22dt4/sape22dt4mid2019msoasyoaestimatesunformatted.zip', 'population.xlsx')
getSheetNames('./download/population.xlsx')
y <- as.data.table(read.xlsx('./download/population.xlsx', 'Mid-2019 Persons', startRow = 5))
y[, 2:6 := NULL]
setnames(y, c(1:2, ncol(y)), c('MSOA', 'TOT', '90'))
setnames(y, 3:ncol(y), paste0('X', stringr::str_pad(names(y)[3:ncol(y)], 2, pad = '0')))
write_fst(y, './data/population')

## Index of Multiple deprivation (IMD 2019) NOTE: highest score <=> lowest rank/decile => worst situation
download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/833978/File_5_-_IoD2019_Scores.xlsx', './download/imd.xlsx')
getSheetNames('./download/imd.xlsx')
y <- as.data.table(read.xlsx('./download/imd.xlsx', 'IoD2019 Scores'))
y <- y[, c(1, 5)]
setnames(y, c('LSOA', 'IMD'))
write_fst(y, './data/imd')

## Income (FA2018)
download.file('https://www.ons.gov.uk/file?uri=%2femploymentandlabourmarket%2fpeopleinwork%2fearningsandworkinghours%2fdatasets%2fsmallareaincomeestimatesformiddlelayersuperoutputareasenglandandwales%2ffinancialyearending2018/netannualincomebeforehousingcosts2018.csv', './download/income.csv')
y <- fread('./download//income.csv', skip = 4, select = c(1, 7), col.names = c('MSOA', 'income'))
y[, income := as.integer(gsub(',| ', '', income))]
write_fst(y, './data/income')

## House Prices (Mar-2020)
dunzip('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fhousing%2fdatasets%2fhpssadataset2medianhousepricebymsoaquarterlyrollingyear%2fcurrent/hpssadataset2medianpricepaidbymsoa.zip', 'house_prices.xls')
excel_sheets('./download//house_prices.xls')
y <- as.data.table(read_xls('./download/house_prices.xls', '1a', skip = 4))
# delete all unwanted columns at the end
while(sum(y[, get(names(y)[ncol(y)])], na.rm = TRUE) == 0) y[, names(y)[ncol(y)] := NULL]
y <- y[, .(MSOA = `MSOA code`, house_price = get(names(y)[ncol(y)]))]
write_fst(y, './data/house_prices')

## Energy and Gas Consumption (2018)
download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/868764/MSOA_domestic_elec_2010-18.xlsx', './download/energy_dom.xlsx')
getSheetNames('./download/energy_dom.xlsx')
y <- as.data.table(read.xlsx('./download/energy_dom.xlsx', '2018', startRow = 2, cols = c(4, 7)))
setnames(y, c('MSOA', 'energy.d'))

download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/868770/MSOA_non-domestic_elec_2010-18.xlsx', './download/energy_nondom.xlsx')
yt <- as.data.table(read.xlsx('./download/energy_nondom.xlsx', '2018', startRow = 2, cols = c(4, 7)))
setnames(yt, c('MSOA', 'energy.nd'))
y <- yt[y, on = 'MSOA']

download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/868749/MSOA_domestic_gas_2010-18.xlsx', './download/gas_dom.xlsx')
yt <- as.data.table(read.xlsx('./download/gas_dom.xlsx', '2018', startRow = 2, cols = c(4, 7)))
setnames(yt, c('MSOA', 'gas.d'))
y <- yt[y, on = 'MSOA']

download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/868753/MSOA_non-domestic_gas_2010-18.xlsx', './download/gas_nondom.xlsx')
yt <- as.data.table(read.xlsx('./download/gas_nondom.xlsx', '2018', startRow = 2, cols = c(4, 7)))
setnames(yt, c('MSOA', 'gas.nd'))
y <- yt[y, on = 'MSOA']

write_fst(y, './data/consumption')


### Boundaries MSOA -----
dunzip('https://opendata.arcgis.com/datasets/23cdb60ee47e4fef8d72e4ee202accb0_0.zip', 'MSOA', 'Middle')

### Clean and Exit -----
rm(list = ls())
gc()
