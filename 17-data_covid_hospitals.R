#################################################
# GIS DAY 2020 * DATA COVID - HOSPITAL ACTIVITY #
#################################################

# load packages
pkgs <- c('data.table', 'fst', 'openxlsx')
lapply(pkgs, require, char = TRUE)

# Weekly report
url <- 'https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/11/Weekly-covid-admissions-and-beds-publication-201112-1.xlsx'
tmp = tempfile()
download.file(url, destfile = tmp, mode = 'wb')
snms <- getSheetNames(tmp)
snms <- snms[!grepl('Lookup', snms)]
dts <- rbindlist(lapply(
    snms[2:length(snms)], 
    function(sn){
        message('Processing Sheet: ', sn)
        y <- setDT(read.xlsx(tmp, sheet = sn, startRow = 15, detectDates = TRUE))
        y <- y[!is.na(NHS.England.Region)][, `:=`( NHS.England.Region = NULL, Name = NULL)]
        data.table( file = sn, melt(y, variable.factor = FALSE) )
    }
))
unlink(tmp)
setnames(dts, c('report', 'is_t1_Acute', 'TRST', 'day', 'cases'))
dts[is.na(cases), cases := 0]
dts[, day := as.Date(as.numeric(day), origin = '1899-12-30')]

# adding attribute to trusts (only first time)
# y <- readRDS('./data/datasets')
# y[['TRST']] <- unique(dts[, .(TRST, is_t1_Acute)])[y[['TRST']], on = 'TRST']
# setcolorder(y[['TRST']], c('TRST', 'TRSTn', 'is_foundation', 'is_t1_Acute'))
# saveRDS(y, './data/datasets')

# keep only NHS Trusts, then save
y <- readRDS('./data/datasets')
dts[, is_t1_Acute := NULL]
dts <- dts[TRST %chin% y[['TRST']]$TRST]
write_fst(dts, './covid/hospitals')

# Clean and Exit
rm(list = ls())
gc()
