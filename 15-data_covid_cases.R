#######################################################################
# GIS DAY 2020 * DATA COVID - CASES - UTLA / LTLA DAILY + MSOA WEEKLY #
#######################################################################

# load packages
pkgs <- c('data.table', 'fst', 'openxlsx')
lapply(pkgs, require, char = TRUE)

# load dataset
dts <- readRDS('./data/datasets')

## Weekly Cases by MSOA
y <- fread('https://coronavirus.data.gov.uk/downloads/msoa_data/MSOAs_latest.csv', select = c(1, 3, 4))
setnames(y, c('MSOA', 'week', 'cases'))
y[is.na(cases), cases := 1]
y <- y[order(MSOA, -week)][, rweek := 1:.N, MSOA]
write_fst(y, './covid/cases_msoa')

# Add total + last week/fortnight cases + rates
yx <- dts[['MSOA']][, 1:(which(names(dts[['MSOA']]) == 'tc') - 1)]
dn <- names(yx)
yx <- y[, .(tc = sum(cases)), MSOA][yx, on = 'MSOA'][, tr := round(tc / population * 1e5, 2)]
yx <- y[rweek == 1, .(MSOA, wc = cases)][yx, on = 'MSOA'][, wr := round(wc / population * 1e5, 2)]
yx <- y[rweek == 2, .(MSOA, pc = cases)][yx, on = 'MSOA'][, pr := round(pc / population * 1e5, 2)]
yx <- y[rweek <= 2, .(fc = sum(cases)), MSOA][yx, on = 'MSOA'][, fr := round(fc / population * 1e5, 2)]
yx <- y[rweek %in% 3:4, .(bc = sum(cases)), MSOA][yx, on = 'MSOA'][, br := round(bc / population * 1e5, 2)]
yx[, `:=`( wpr = wr / pr - 1, wfr = wr / fr - 1, fbr = fr / br - 1 )]
setcolorder(yx, c(dn, 'tc', 'wc', 'pc', 'fc', 'bc'))
dts[['MSOA']] <- yx
saveRDS(dts, './data/datasets')


## Daily Cases by LTLA
y <- fread('https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv', select = 2:5)
setnames(y, c('LTLA', 'type', 'day', 'cases'))
y <- y[type == 'ltla' & day < max(day)][, type := NULL]
y <- y[order(LTLA, -day)][, rweek := floor((1:.N - 1)/ 7) + 1, LTLA]
write_fst(y, './covid/cases_ltla')

# Add total + last week/fortnight cases + rates
yx <- dts[['LTLA']][, 1:(which(names(dts[['LTLA']]) == 'tc') - 1)]
dn <- names(yx)
yx <- y[, .(tc = sum(cases)), LTLA][yx, on = 'LTLA'][, tr := round(tc / population * 1e5, 2)]
yx <- y[rweek == 1, .(wc = sum(cases)), LTLA][yx, on = 'LTLA'][, wr := round(wc / population * 1e5, 2)]
yx <- y[rweek == 2, .(pc = sum(cases)), LTLA][yx, on = 'LTLA'][, pr := round(pc / population * 1e5, 2)]
yx <- y[rweek <= 2, .(fc = sum(cases)), LTLA][yx, on = 'LTLA'][, fr := round(fc / population * 1e5, 2)]
yx <- y[rweek %in% 3:4, .(bc = sum(cases)), LTLA][yx, on = 'LTLA'][, br := round(bc / population * 1e5, 2)]
yx[, `:=`( wpr = wr / pr - 1, wfr = wr / fr - 1, fbr = fr / br - 1 )]
setcolorder(yx, c(dn, 'tc', 'wc', 'pc', 'fc', 'bc'))
dts[['LTLA']] <- yx
saveRDS(dts, './data/datasets')

## Daily Cases by UTLA
y <- fread('https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv', select = 2:5)
setnames(y, c('UTLA', 'type', 'day', 'cases'))
y <- y[type == 'utla' & day < max(day)][, type := NULL]
y <- y[order(UTLA, -day)][, rweek := floor((1:.N - 1)/ 7) + 1, UTLA]
write_fst(y, './covid/cases_utla')

# Add total + last week/fortnight cases + rates
yx <- dts[['UTLA']][, 1:(which(names(dts[['UTLA']]) == 'tc') - 1)]
dn <- names(yx)
yx <- y[, .(tc = sum(cases)), UTLA][yx, on = 'UTLA'][, tr := round(tc / population * 1e5, 2)]
yx <- y[rweek == 1, .(wc = sum(cases)), UTLA][yx, on = 'UTLA'][, wr := round(wc / population * 1e5, 2)]
yx <- y[rweek == 2, .(pc = sum(cases)), UTLA][yx, on = 'UTLA'][, pr := round(pc / population * 1e5, 2)]
yx <- y[rweek <= 2, .(fc = sum(cases)), UTLA][yx, on = 'UTLA'][, fr := round(fc / population * 1e5, 2)]
yx <- y[rweek %in% 3:4, .(bc = sum(cases)), UTLA][yx, on = 'UTLA'][, br := round(bc / population * 1e5, 2)]
yx[, `:=`( wpr = wr / pr - 1, wfr = wr / fr - 1, fbr = fr / br - 1 )]
setcolorder(yx, c(dn, 'tc', 'wc', 'pc', 'fc', 'bc'))
dts[['UTLA']] <- yx
saveRDS(dts, './data/datasets')

## Daily Cases by age class LTLA -----
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

# Add total + last week/fortnight cases + rates
# !==> Add code here <==!

## Clean and Exit -----
rm(list = ls())
gc()
