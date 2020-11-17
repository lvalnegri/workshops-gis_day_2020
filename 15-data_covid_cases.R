#######################################################################
# GIS DAY 2020 * DATA COVID - CASES - UTLA / LTLA DAILY + MSOA WEEKLY #
#######################################################################

# load packages
pkgs <- c('data.table', 'fst', 'openxlsx')
lapply(pkgs, require, char = TRUE)

# Weekly Cases by MSOA
y <- fread('https://coronavirus.data.gov.uk/downloads/msoa_data/MSOAs_latest.csv', select = c(1, 3, 4))
setnames(y, c('MSOA', 'week', 'cases'))
write_fst(y, './covid/cases_msoa')

# Daily Cases by LTLA
y <- fread('https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv', select = 2:5)
setnames(y, c('LTLA', 'type', 'day', 'cases'))
y <- y[type == 'ltla'][, type := NULL]
write_fst(y, './covid/cases_ltla')

# Daily Cases by age class LTLA
y <- fread(
        'https://coronavirus.data.gov.uk/downloads/demographic/cases/specimenDate_ageDemographic-stacked.csv', 
        select = c("areaType", "areaCode", "date", "age", "newCasesBySpecimenDate")
)
setnames(y, c('type', 'LTLA', 'day', 'age', 'cases'))
y <- y[type == 'ltla'][, type := NULL]
y <- y[!grepl('un', age)]
y1 <- y[!age %chin% c('60+', '0_59')]
y1[, age := factor(age, levels = unique(y1$age), ordered = TRUE)]
write_fst(y1, './covid/cases_ltla_age1')
y2 <- y[age %chin% c('0_59', '60+')]
y2[, age := factor(age, ordered = TRUE)]
write_fst(y2, './covid/cases_ltla_age2')

# Clean and Exit
rm(list = ls())
gc()
