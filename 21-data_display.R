###############################
# GIS DAY 2020 * DATA DISPLAY #
###############################

# load packages
pkgs <- c('data.table')
lapply(pkgs, require, char = TRUE)

# load data
bnd <- readRDS('./boundaries/bpundaries')
dts <- read_fst('./data/dataset')
cvd <- read_fst('./data/covid')

