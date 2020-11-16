##################################################
# GIS DAY 2020 * DATA COVID - NHS CALLS + ONLINE #
##################################################

# load packages
pkgs <- c('data.table', 'fst')
lapply(pkgs, require, char = TRUE)

# Calls (NHS Pathways 111+999) by CCG + Age & Sex
y <- fread(
        'https://files.digital.nhs.uk/98/3BA4EE/NHS%20Pathways%20Covid-19%20data%202020-11-12.csv',
        select = c('SiteType', 'Call Date', 'Sex', 'AgeBand',  'CCGCode', 'TriageCount'),
        na.strings = c('', 'Unknown', 'NULL')
)
setnames(y, c('site', 'day', 'sex', 'age', 'CCG', 'calls'))
y[, age := gsub(' years', '', age)]
y[, `:=`(
    day = as.Date(day),
    sex = factor(sex),
    age = factor(age, ordered = TRUE)
)]
write_fst(y, './covid/calls_ccg')

# Calls (NHS Pathways 111+999) by UTLA
y <- fread(
        'https://files.digital.nhs.uk/5C/046028/NHS%20Pathways%20Covid-19%20data_UTLA_2020-11-12.csv',
        select = c('SiteType', 'CallDate', 'UTLACode', 'TriageCount')
)
setnames(y, c('site', 'day', 'UTLA', 'calls'))
y[, day := as.Date(day)]
write_fst(y, './covid/calls_utla')

# Online (111)
# https://files.digital.nhs.uk/BE/AFF48C/111%20Online%20Covid-19%20data_2020-11-12.csv
y <- fread(
        'https://files.digital.nhs.uk/BE/AFF48C/111%20Online%20Covid-19%20data_2020-11-12.csv',
        select = c('journeydate', 'sex', 'ageband',  'ccgcode', 'Total'),
        na.strings = c('', 'Unknown', 'NULL')
)
setnames(y, c('day', 'sex', 'age', 'CCG', 'journeys'))
y <- y[!is.na(CCG)]
y[, age := gsub(' years', '', age)]
y[, `:=`(
    day = as.Date(day),
    sex = factor(sex),
    age = factor(age, ordered = TRUE)
)]
write_fst(y, './covid/online')


# Clean and Exit
rm(list = ls())
gc()
