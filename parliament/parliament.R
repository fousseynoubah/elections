##########################################################################
########################################/// FUSEAU HORAIRE ///
##########################################################################
#Sys.setenv(TZ="Africa/Bamako") #Sys.getenv("TZ") # to check

##########################################################################
########################################/// PACKAGES ///
##########################################################################
library("tidyverse")
library("rvest")
library("downloader")
library("rgdal")

##########################################################################
########################################/// THEME ///
##########################################################################
#Setting the theme for ggplot
theme_set(theme_bw())

##########################################################################
########################################/// CONNEXION ODBC ///
##########################################################################
#Connexion au DSN (Data Source Name): création d'un chaîne de connexion
#aeroports.odbc <- odbcConnect(dsn ="aeroports", uid = " ", pwd = " ")  # Source de dépôt


##########################################################################
########################################/// ASSEMBLEE: DEPUTES
##########################################################################

############################## ASSEMBLEE: LISTE DES DEPUTES
## Liste des députés
pages <- data_frame(
  pages = c("http://assemblee-nationale.ml/liste-des-deputes/page/",
          paste0("http://assemblee-nationale.ml/liste-des-deputes/page/", seq(from = 20, to = 140, by = 20))
)
  )

mp_list <- list()

for(i in 1:nrow(pages)){
  mp_list[[i]] <- pages[i, "pages"] %>% 
    paste() %>% 
    read_html() %>% 
    html_nodes('.caption') %>% 
    html_text() %>% 
    as_data_frame() %>% 
    mutate(value = str_trim(value),
           value = str_remove(value, "contacter")) %>% 
    separate(value, c("candidate", "district"), sep = " - " ) %>% 
    mutate(district = str_remove(district, "\r\r\n\t\t\t\t"),
           district = str_trim(district),
           party = word(candidate, -1),
           candidate = str_remove(candidate, party),
           candidate = str_trim(candidate),
           lastname = word(candidate, -1),
           candidate = str_remove(candidate, lastname),
           candidate = str_trim(candidate)) %>% 
    separate(candidate, c("firstname", "middlename")) %>%
    select(firstname, middlename, lastname, party, district)
  rm(i)
  }

mp_df <- do.call(rbind, mp_list) 
mp_df <- mp_df %>% 
  mutate(party = ifelse(party == "ADEMA-PASJ", "ADEMA/PASJ",
                        ifelse(party == "ADP-MAILABA", "ADP/MALIBA",
                               ifelse(party == "ADP-MAILABA", "ADP/MALIBA",
                                      ifelse(party == "ADP-MALIBA", "ADP/MALIBA", party))))) #corrections
  
rm(mp_list, pages, i)

##########################################################################
########################################/// MAPPING : DOWNLOADING AND TRANSFORMING THE SHAPEFILES
##########################################################################
### Data frame
map_df <- data_frame(name = c("region", "cercle", "commune"),
             link = c("https://data.humdata.org/dataset/3feaf6d7-8b21-4db1-a097-fa8a2b680a89/resource/1f4755a2-b3d7-4634-9273-430048d40684/download/mli_admbnda_adm1_pop_2017.zip",
                      "https://data.humdata.org/dataset/3feaf6d7-8b21-4db1-a097-fa8a2b680a89/resource/bc251c53-9c78-48b2-ab8f-c92d9269faf2/download/mli_admbnda_adm2_pop_2017.zip",
                      "https://data.humdata.org/dataset/3feaf6d7-8b21-4db1-a097-fa8a2b680a89/resource/303f57d8-965f-4c70-a081-3e5e0fcba2bf/download/mli_admbnda_adm3_pop_2017.zip"))

### Download and unzip
for(i in 1:nrow(map_df)){
  download(paste(map_df[i, "link"]), 
           dest = paste(map_df[i, "name"], "zip", sep = "_"), 
           mode="wb") 
  unzip(paste(map_df[i, "name"], "zip", sep = "_"),
        exdir = paste(map_df[i, "name"]))
  file.remove(paste(map_df[i, "name"], "zip", sep = "_"))
  rm(i)
}

### Transforming the shapefiles
shp_list <- list()

for(i in 1:nrow(map_df)){
  myshp <- readOGR(paste0(map_df[i, "name"],"/","mli_admbnda_adm", i ,"_pop_2017.shp"))
  shp_list[[i]] <- maps::map(myshp) %>% 
    fortify() %>%
    mutate(region = as.numeric(region)) %>% # fortify created a string instead of a numeric variable
    left_join(data.frame(myshp@data) %>%
                rename(region = OBJECTID) %>%
                mutate(region = region - 1), 
              by = c("region"))
  rm(myshp)
  rm(i)
}

map_region <- shp_list[[1]] %>% as_data_frame()
map_cercles <- shp_list[[2]] %>% as_data_frame()
map_communes <- shp_list[[3]] %>% as_data_frame()

### Remove unneeded objects
#Zip files
for(i in 1:nrow(map_df)){
  unlink(paste(map_df[i, "name"]), recursive = TRUE)
  rm(i)
}

# Objects in working environment
rm(map_df, shp_list)



##########################################################################
########################################/// JOINING THE DATA
##########################################################################

### Using two files I generated from the different sources: parliament and shapefile
### Not the best solution, but let's go with that for now
#mp_df %>% 
#  group_by(district) %>% 
#  summarise(n()) %>% 
#  write_excel_csv("mp_district.csv", na = "")

#cercles_map %>% 
#  group_by(district = Admin2_Nam) %>% 
#  summarise(n()) %>% 
#  write_excel_csv("map_district.csv", na = "")

join_districts <- readxl::read_excel("join_districts.xlsx")

# Removing the file
#file.remove("join_districts.xlsx")

##########################################################################
########################################/// SAVING THE WORKING ENV.
##########################################################################
save.image("parliament.RData")
