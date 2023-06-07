install.packages("DBI")
library(DBI)
library(bigrquery)
library(tidyverse)

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

#Pointer to heart rate data
heartrate_activity <- tbl(con, "heartrate_activity_merged") %>%
    mutate(Id=as.numeric(Id)) %>%
    distinct() %>%
    mutate(datetime=sql("DATETIME(date,time)"))
glimpse(heartrate_activity)
## 3.4 Million rows by minute/sec!! Let's get those lower but still usable. Result 8499 rows!
heartrate_hourly_activity <- heartrate_activity %>%
    mutate(hour=sql("DATETIME_TRUNC(datetime, hour)")) %>%
    select(Id,hour,Value) %>%
    group_by(Id,hour ) %>%
    summarise(avg_heartrate=mean(Value),min_heartrate=min(Value),max_heartrate=max(Value)) %>%
    glimpse()
glimpse(heartrate_hourly_activity)
#Graph usage time or active device time by users
heartrate_hourly_activity %>%
    mutate(day=sql("DATETIME_TRUNC(hour,day)")) %>%
    group_by(day) %>%
    summarize(users=count(distinct(Id))) %>%
    arrange(desc(day)) %>%
    ggplot(aes(day,users))+geom_line()+geom_smooth()+
    scale_x_datetime(date_labels = "%m/%d", breaks="3 days")+
    scale_y_continuous(breaks=seq(0,14,by=2))
#Graph in slow usage time
heartrate_hourly_activity %>%
    filter(hour>"2016-04-10 00:00:00" & hour<"2016-04-13 00:00:00") %>%
    group_by(hour) %>%
    summarize(users=count(distinct(Id))) %>%
    arrange(desc(hour)) %>%
    ggplot(aes(hour,users))+geom_line()+geom_smooth() +
    scale_y_continuous(breaks=seq(0,14,by=2)) +
    scale_x_datetime(date_labels = "%m/%d/%H:%M", breaks="6 hours")

daily_activity <- tbl(con,"daily_activity_merged") %>%
    mutate(Id=as.numeric(Id)) %>%
    select(Id,ActivityDate,TotalSteps,TotalDistance,Calories,VeryActiveMinutes,FairlyActiveMinutes,LightlyActiveMinutes,SedentaryMinutes) %>%
    distinct()
    #%>% show_query()
glimpse(daily_activity)
## Daily activity summary 
summary_daily_activity <- daily_activity%>%
    summarise(Total_users=n_distinct(Id),Days_w_data=n_distinct(ActivityDate),AvgSteps=mean(TotalSteps),AvgDistance=mean(TotalDistance),AvgCalories=mean(Calories))
glimpse(summary_daily_activity)
## Summary by day of the week

summary_by_day <- daily_activity%>%
    mutate(day_week=sql("format_date('%a', ActivityDate)")) %>%
    mutate(dw=sql("EXTRACT(DAYOFWEEK FROM ActivityDate)")) %>%
    # EXTRACT(DAYOFWEEK FROM ActivityDate) output is WEEKDAY as number, also WEEKDAY begins on Sunday(1)
    group_by(day_week,dw) %>%
    summarise(AvgCalories=mean(Calories),AvgSteps=mean(TotalSteps),AvgDistance=mean(TotalDistance),VeryActiveMinutes=mean(VeryActiveMinutes),FairlyActiveMinutes=mean(FairlyActiveMinutes),LightlyActiveMinutes=mean(LightlyActiveMinutes),SedentaryMinutes=mean(SedentaryMinutes)) %>%
    arrange(dw) 
#We can't really judge by the sum of Minutes or Distance since there aren't the same number of observations in the data for each participant. Therefore we'll use the mean

glimpse(summary_by_day)

daily_activity %>%
    group_by(ActivityDate) %>%
    summarize(users=count(distinct(Id))) %>%
    arrange(desc(ActivityDate)) %>%
    ggplot(aes(ActivityDate,users))+geom_line()+geom_smooth()+
    scale_x_date(date_labels = "%m/%d", breaks="3 days")+
    scale_y_continuous(breaks=seq(0,36,by=2))

#JOIN the hourly data

