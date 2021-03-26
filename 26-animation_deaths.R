##########################################
# GIS DAY 2020 * Animation Death by date #
##########################################

# load libraries
pkg <- c('popiFun', 'data.table', 'fst', 'gganimate', 'ggplot2', 'ggthemes')
invisible(lapply(pkg, require, char = TRUE))

# set constants
data_path <- file.path(pub_path, 'datasets', 'shiny_apps', 'uk_covid')

# load dataset
dts.t <- read_fst(file.path(data_path, 'trust_data'), as.data.table = TRUE)

# transform dataset: sum over trust, cast+melt to add all dates, calculate cumulates
y <- dts.t[!is.na(date_reported) & date_happened > '2020-03-15'][, .(N = sum(N)), .(date_reported, date_happened)]
y <- melt(
        dcast(y, date_reported~date_happened, fill = 0), 
        id.vars = 'date_reported', 
        variable.name = 'date_happened', 
        variable.factor = FALSE,
        value.name = 'N', 
)
y[, date_happened := as.Date(date_happened)]
y[, cN := cumsum(N), date_happened]

# add palette 
yd <- unique(y$date_reported)
yp <- colorRampPalette(c('white', 'red', 'darkred'))(length(yd))
y <- data.table(date_reported = yd, palette = yp)[y, on = 'date_reported']
# plot(rep(1, length(yp)), col = unique(yp), pch = 19, cex = 3)

# convert date in factor
y[, fdate_reported := factor(date_reported)]

# add label for last plot in ani
y[, cLabel := ''][date_reported == max(date_reported), cLabel := cN]

# add rolling total deaths as annotation
ya <- y[, .(tN = sum(cN)), fdate_reported]

dr <- '2020-04-23' 
# yr <- y[date_reported >= dr]
gp <- ggplot(y, aes(date_happened, cN, fill = fdate_reported)) + 
        geom_col(show.legend = FALSE) +
        scale_x_date(breaks = '5 days', labels = scales::date_format('%d %b')) +
        scale_fill_manual(values = yp) +
        geom_text(aes(y = cN, label = cLabel), vjust = -0.6, color = 'darkred', size = 3) +
        labs(
            title = 'CoViD-19 Deaths in NHS England Hospitals', 
            subtitle = 'Report Day: {format(as.Date(closest_state), "%d %B")}',
            caption = '@2020 datamaps.uk',
            x = 'Date of Death', 
            y = 'Cumulated Deaths'
        ) +
        geom_text(
            data = ya, 
            x = min(y$date_happened) + 6, 
            y = max(y$cN), 
            aes(label = paste('Total Deaths:', format(tN, big.mark = ','))), 
            size = 8,
            show.legend = FALSE
        ) +
        theme_clean() +
        transition_states(fdate_reported) +
        ease_aes('linear')

# build the animation
anm <- animate(gp, renderer = gifski_renderer(loop = FALSE), width = 900, height = 762)

# save the animation
anim_save('nhsengland_covid19_deaths.gif')
