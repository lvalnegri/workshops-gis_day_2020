#################################################
# GIS DAY 2020 * DATA COVID - HOSPITAL ACTIVITY #
#################################################

# load packages
pkgs <- c('data.table', 'fst', 'openxlsx')
lapply(pkgs, require, char = TRUE)

# define wrangling function
tidy_data <- function(fdef, srow){
    tmp = tempfile()
    download.file(fdef, destfile = tmp, mode = 'wb')
    snms <- getSheetNames(tmp)
    snms <- snms[!grepl('Lookup|Summary', snms)]
    dts <- rbindlist(lapply(snms, 
        function(sn){
            message('Processing Sheet: ', sn)
            y <- setDT(read.xlsx(tmp, sheet = sn, startRow = srow))
            y <- y[!is.na(get(names(y)[2]))][, c(1, 2, 4) := NULL]
            message(' - Total sum: ', formatC(sum(y[, lapply(.SD, sum, na.rm = TRUE), .SDcols = 2:ncol(y)]), format = 'd', big.mark = ','))
            data.table( file = sn, melt(y, id.vars = 1, variable.factor = FALSE) )
        }
    ))
    unlink(tmp)
    dts
}

# retrieve file links
url <- 'https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-hospital-activity/'
html <- paste(readLines(url), collapse = '\n')
matched <- stringr::str_match_all(html, "<a href=\"(.*?xlsx)\"")
links <- matched[[1]][, 2]

# monthly report
y1 <- tidy_data(links[!grepl('weekly|daily', tolower(links))], 13)

# Weekly report
y2 <- tidy_data(links[grepl('weekly', tolower(links))], 15)

# combine and clean
dts <- rbindlist(list( y1, y2 ))
setnames(dts, c('report', 'TRST', 'day', 'cases'))
dts <- dts[!is.na(cases)][, day := as.Date(as.numeric(day), origin = '1899-12-30')]

# adding attribute to trusts (only first time)
# y <- readRDS('./data/datasets')
# y[['TRST']] <- unique(dts[, .(TRST, is_t1_Acute)])[y[['TRST']], on = 'TRST']
# setcolorder(y[['TRST']], c('TRST', 'TRSTn', 'is_foundation', 'is_t1_Acute'))
# saveRDS(y, './data/datasets')
# dts[, is_t1_Acute := NULL]

# keep only NHS Trusts, then save
y <- readRDS('./data/datasets')
dts <- dts[TRST %chin% y[['TRST']]$TRST]
write_fst(dts, './covid/hospitals')

# Clean and Exit
rm(list = ls())
gc()
