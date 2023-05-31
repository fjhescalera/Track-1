library(tidyverse)
sleep_activity <- read.csv("C:\\Users\\fjhes\\OneDrive\\Escritorio\\Bellabeat\\Fitabase Data 4.12.16-5.12.16\\sleepDay_merged.csv") %>%
    mutate("SleepDay"=mdy_hms(gsub("AM","",SleepDay)))
str_trim(sleep_activity$SleepDay)%>%
    sub("AM","",)
View(sleep_activity$SleepDay)
head(sleep_activity)
