##########################################################################
########################################/// FUSEAU HORAIRE ///
##########################################################################
#Sys.setenv(TZ="Africa/Bamako") #Sys.getenv("TZ") # to check

##########################################################################
########################################/// PACKAGES ///
##########################################################################
library("tidyverse")
library("downloader")
library("readxl")
library("rgdal")

##########################################################################
########################################/// PRESIDENTIAL 2013
##########################################################################

############################## PRESIDENTIAL: 2013
## 2013

#url2013 <- "https://en.wikipedia.org/wiki/Malian_presidential_election,_2013"

#url <- "http://africanelections.tripod.com/ml.html#2007_Presidential_Election"

#tableau <- 
#  url2013 %>% 
#  paste() %>% 
#  read_html() %>% 
#  html_nodes('table')%>% 
#  html_table(fill = TRUE)

#dataframe <- map(tableau, as_data_frame)

##########################################################################
########################################/// PRESIDENTIAL 2018
##########################################################################
# Commune
list_commune <- read_excel("presidential/liste_electorale.xlsx", sheet = "commune")

list_commune <- list_commune %>% 
  filter(!is.na(Admin0_Nam))

# Retrait des cartes
retrait_cercle <- read_excel("presidential/liste_electorale.xlsx", sheet = "retrait_cercle")
retrait_region <- read_excel("presidential/liste_electorale.xlsx", sheet = "retrait_region")

##########################################################################
########################################/// CARTOGRAPHIE : TELECHARGEMENT ET TRANSFORMATION DES SHAPEFILES
########################################/// MAPPING : DOWNLOADING AND TRANSFORMING THE SHAPEFILES
##########################################################################
### Data frame
map_df <- data_frame(name = c("region", "cercle", "commune"),
                     link = c("https://data.humdata.org/dataset/3feaf6d7-8b21-4db1-a097-fa8a2b680a89/resource/1f4755a2-b3d7-4634-9273-430048d40684/download/mli_admbnda_adm1_pop_2017.zip",
                              "https://data.humdata.org/dataset/3feaf6d7-8b21-4db1-a097-fa8a2b680a89/resource/bc251c53-9c78-48b2-ab8f-c92d9269faf2/download/mli_admbnda_adm2_pop_2017.zip",
                              "https://data.humdata.org/dataset/3feaf6d7-8b21-4db1-a097-fa8a2b680a89/resource/303f57d8-965f-4c70-a081-3e5e0fcba2bf/download/mli_admbnda_adm3_pop_2017.zip"))

### Télécharger et décompresser / Download and unzip
for(i in 1:nrow(map_df)){
  download(paste(map_df[i, "link"]), 
           dest = paste(map_df[i, "name"], "zip", sep = "_"), 
           mode="wb") 
  unzip(paste(map_df[i, "name"], "zip", sep = "_"),
        exdir = paste(map_df[i, "name"]))
  file.remove(paste(map_df[i, "name"], "zip", sep = "_"))
  rm(i)
}

### Transformation des shapefiles / Transforming the shapefiles
shp_list <- list()

for(i in 1:nrow(map_df)){
  shp_list[[i]] <- readOGR(paste0(map_df[i, "name"],"/","mli_admbnda_adm", i ,"_pop_2017.shp"))
  #rm(i)
}

map_region <- shp_list[[1]]
map_cercles <- shp_list[[2]]
map_communes <- shp_list[[3]]

### Remove unneeded objects
#Zip files
for(i in 1:nrow(map_df)){
  unlink(paste(map_df[i, "name"]), recursive = TRUE)
  rm(i)
}

# Objects in working environment
rm(map_df, shp_list)

######################################################################################################
### SAUVEGARDE DES DONNEES / SAVING THE DATA
######################################################################################################

save.image("presidential/presidential_map_data.RData")




