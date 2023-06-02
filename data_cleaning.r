install.packages("DBI")
library(DBI)
library(bigrquery)
library(tidyverse)

sleep_activity <- read.csv("C:\\Users\\fjhes\\OneDrive\\Escritorio\\Bellabeat\\Fitabase Data 4.12.16-5.12.16\\sleepDay_merged.csv") %>%
    mutate("SleepDay"=mdy_hms(gsub("AM","",SleepDay)))
str_trim(sleep_activity$SleepDay)%>%
    sub("AM","",)
View(sleep_activity$SleepDay)
head(sleep_activity)

# Connect to BigQuery
# con <- dbConnect(
# bigrquery::bigquery(),
# project = "PROJECT_ID",
# dataset = DATASET_NAME,
# billing = PROJECT_ID
# )
# con

con <- dbConnect(
bigrquery::bigquery(),
project = "warm-utility-374917",
dataset = "Bellabeat"
)
con
#Show the tables
dbListTables(con)
#Handle authentication
bigrquery::bq_auth()
# Since we get this error when trying to _lazy_ly query the table : In as.integer.integer64(x) : NAs produced by integer overflow
# We'll need to CAST these IDs to numeric value, we can use dplyr verbs to affect the query we'll send to BigQuery, in this case we don't get the
#  data first and then do the transformations but rather a query is built with our verbs  
daily_activity <- tbl(con,"daily_activity_merged") %>%
    mutate(Id=as.numeric(Id)) %>%
    select(Id,ActivityDate,TotalSteps,TotalDistance,Calories)
    #%>% show_query()
glimpse(daily_activity)
