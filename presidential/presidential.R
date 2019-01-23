##########################################################################
########################################/// FUSEAU HORAIRE ///
##########################################################################
Sys.setenv(TZ="Africa/Bamako") #Sys.getenv("TZ") # to check

##########################################################################
########################################/// PACKAGES ///
##########################################################################
library(tidyverse)
library(downloader)
library(readxl)
#library(rgdal)
library(sf)


##########################################################################
########################################/// PRESIDENTIAL 2018: DATA
##########################################################################

# Age
presidential_voters_age <- read_excel("presidential/presidential_data.xlsx", sheet = "voters_age")
names(presidential_voters_age) <- c("age", "male", "female", "total")
presidential_voters_age <- presidential_voters_age %>% 
  gather(key = group, value = voters, -age)

# Population
census_2009_popage <- read_excel("presidential/presidential_data.xlsx", sheet = "popage_2009")

census_2009_popage <- census_2009_popage %>% 
  gather(key = group, value = population, -c(code, age)) %>% 
  separate(group, c("sex", "situation"), sep = "_")

# Withdrawal (region)
presidential_withdrawal_region <-  read_excel("presidential/presidential_data.xlsx", sheet = "retrait_region")

  
# Withdrawal (district)
presidential_withdrawal_district <- read_excel("presidential/presidential_data.xlsx", sheet = "retrait_cercle")
  
# Candidates
presidential_candidates <- read_excel("presidential/presidential_data.xlsx", sheet = "CANDIDATES")

# List
presidential_list <- read_excel("presidential/presidential_data.xlsx", sheet = "LIST")

# Results
presidential_results <- list()
for(i in c("KAYES","KOULIKORO", "SIKASSO", "SEGOU", "MOPTI", "TOMBOUCTOU", "GAO", "KIDAL", "BAMAKO")){
  presidential_results[[i]] <- read_excel(path = "presidential/presidential_data.xlsx", sheet = paste0(i) )
}

presidential_results <- do.call(rbind, presidential_results)

rm(i)

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
  shp_list[[i]] <- st_read(paste0(map_df[i, "name"],"/","mli_admbnda_adm", i ,"_pop_2017.shp"))
}

map_region_sf <- shp_list[[1]]
map_district_sf <- shp_list[[2]]
map_municipality_sf <- shp_list[[3]]

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

save.image("presidential/presidential_data.RData")
