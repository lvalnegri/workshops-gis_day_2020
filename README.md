## GIS DAY 2020: Mapping CoViD in the UK using *R* and *Shiny*


### Boundaries

 - [MSOA England and Wales](https://opendata.arcgis.com/datasets/87aa4eb6393644768a5f85929cc704c2_0.zip) Super Generalized
 
 - [LTLA United Kingdom](https://opendata.arcgis.com/datasets/910f48f3c4b3400aa9eb0af9f8989bbe_0.zip) Ultra Generalized
 
 - [rmapshaper]() is an *R* package of spatial tools, in this case to further *simplify* the polygons.


### Data

 - [Covid cases by LTLA](https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv)
 
 - [Covid cases by MSOA](https://coronavirus.data.gov.uk/downloads/msoa_data/MSOAs_latest.csv)
 
 - [Population mid-2019 by MSOA](https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/middlesuperoutputareamidyearpopulationestimates). Use [this file]() and sum over *column E* `LA Code (2020 boundaries)` for the correct LTLA codes that links to the cases files

 - [Household Disposable Income by MSOA]

 - [Median House Prices by MSOA]()

 - [MSOA House of Commons *intelligible* Names](https://visual.parliament.uk/msoanames/static/MSOA-Names-1.7.csv)







## Credits

 - [Gis Day website](https://www.gisday.com/en-us/overview)
