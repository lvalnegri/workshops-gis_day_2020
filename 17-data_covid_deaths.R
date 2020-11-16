###################################################
# GIS DAY 2020 * DATA COVID - TRUSTS DAILY DEATHS #
###################################################

# load packages
pkgs <- c('data.table', 'fst', 'openxlsx')
lapply(pkgs, require, char = TRUE)

url <- 'https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-daily-deaths/'
html <- paste(readLines(url), collapse = '\n')
matched <- stringr::str_match_all(html, "<a href=\"(.*?)\"")
links <- matched[[1]][, 2]
links <- links[grepl('COVID-19-daily-announced-deaths', links)]
tmp <- tempfile()
dts <- data.table()
for(dt in links){
    dtt <- gsub('COVID-19-daily-announced-deaths-|.xlsx', '', basename(dt))
    message('Processing date ', dtt )
    download.file(dt, destfile = tmp, mode = 'wb')
    snms <- getSheetNames(tmp)
    sn <- snms[grepl('TRUST', toupper(snms))]
    y <- as.data.table(read.xlsx(tmp, sn, startRow = 14, detectDates = TRUE))
    y <- y[-1][, c(1, ncol(y) - 1, ncol(y)) := NULL]    
    y <- melt(y, id.vars = c('Code', 'Name'), variable.factor = FALSE, na.rm = TRUE)
    dts <- rbindlist(list( dts, data.table( date_rep = format(as.Date(dtt, '%d-%B-%Y'), '%Y-%m-%d'), y[value > 0]) ))
}
unlink(tmp)
dts[, `:=`(
    date_rep = as.Date(date_rep),
    variable = as.Date(as.numeric(variable), origin = '1899-12-30'),
    Code = factor(Code)
)][, Name := NULL]
setnames(dts, c('date_rep', 'TST', 'date_death', 'count'))
write_fst(dts, './covid/deaths_trusts')


y <- read_fst('./data/trusts', as.data.table = TRUE)

yd <- y[dts, on = 'TST']


# Clean and Exit
rm(list = ls())
gc()
