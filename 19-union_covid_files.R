#####################################
# GIS DAY 2020 * DATA COVID - UNION #
#####################################

fls <- c('cases_msoa', 'cases_ltla', 'cases_ltla_age1', 'cases_ltla_age2', 'deaths_trst', 'hosp_trst', 'calls_ccg', 'calls_utla', 'online_ccg')
y <- lapply(fls, function(x) read_fst(paste0('./covid/', x), as.data.table = TRUE))
names(y) <- fls
saveRDS(y, './covid/covid')

rm(list = ls())
gc()
