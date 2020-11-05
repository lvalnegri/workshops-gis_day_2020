## GIS DAY 2020: Mapping Covid-19 in England *small areas* using *R* and *Shiny*

### *R* Packages

 - [data.table]() and [dplyr]() are two different packages for dealing with datasets

 - [readxl]() to easily read *Excel* files
 
 - [rgdal]() to read the boundaries in *shapefile* format

 - [sp]() to store the spatial objects as a specific *R* class (you can also use the more modern [sf]())

 - [rgeos]() a set of spatial tools

 - [leaflet]() the *R* wrapper for the  eponymous [Javascript library](leaflet.js) that allows to build interactive maps (you can also use the more complete [tmap]() or [mapview](), though they both rely on *leaflet* anyway for the interactive mapping)


### Boundaries

 - [MSOA England and Wales](https://opendata.arcgis.com/datasets/87aa4eb6393644768a5f85929cc704c2_0.zip) Super Generalized
 
 - [LTLA United Kingdom](https://opendata.arcgis.com/datasets/910f48f3c4b3400aa9eb0af9f8989bbe_0.zip) Ultra Generalized
 
 - [CCG United Kingdom](https://opendata.arcgis.com/datasets/910f48f3c4b3400aa9eb0af9f8989bbe_0.zip) Ultra Generalized
 

### Covid Data

 - [Covid Cases by LTLA](https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv)
 
 - [Covid Cases by MSOA](https://coronavirus.data.gov.uk/downloads/msoa_data/MSOAs_latest.csv)
 
 - [Covid Deaths by NHS trusts and Independent Sector Providers](https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-daily-deaths/)
 
 - [Hospital Admissions and Bed Occupancy by NHS trusts and Independent Sector Providers](https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-hospital-activity/)
 
 - [Potential Covid Calls. NHS Pathways and 111 by UTLA and CCG](https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-daily-deaths/)
 

### Ancillary Data

 - [MSOA House of Commons *intelligible* Names](https://visual.parliament.uk/msoanames/static/MSOA-Names-1.7.csv)

 - [MSOA <=> LTLA <=> RGN lookup table](https://coronavirus.data.gov.uk/downloads/supplements/lookup_table.csv)

 - [Small Areas lookup table](https://geoportal.statistics.gov.uk/datasets/output-area-to-lower-layer-super-output-area-to-middle-layer-super-output-area-to-local-authority-district-december-2011-lookup-in-england-and-wales)

### GeoDempgraphics

 - [Population mid-2019 by MSOA](https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/middlesuperoutputareamidyearpopulationestimates)

 - [Output Area Classification]()

 - [Index of Multiple Deprivation 2019](https://www.gov.uk/government/statistics/english-indices-of-deprivation-2019)

 - [Household Disposable Income FA-2018 by MSOA](https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/earningsandworkinghours/datasets/smallareaincomeestimatesformiddlelayersuperoutputareasenglandandwales)

 - [Median House Prices Mar-2020 by MSOA](https://www.ons.gov.uk/peoplepopulationandcommunity/housing/datasets/hpssadataset2medianhousepricebymsoaquarterlyrollingyear)

 - [Electricity and Gas Consumption 2018](https://www.gov.uk/government/statistics/lower-and-middle-super-output-areas-gas-consumption)


## Credits

 - [Gis Day website](https://www.gisday.com/en-us/overview)
