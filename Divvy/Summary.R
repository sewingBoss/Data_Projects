#connecting to bigquery to pull the data

library(bigrquery)
library(dplyr)
df <- dbConnect(
  bigquery(),
  project =  "japanese-grammar-276308",
  dataset = "divvy_project_mana",
  billing = "japanese-grammar-276308"
)

#checking if we got the tables
dbListTables(df)


#some more testing...
main_df <- tbl(df, "cyclistic_combined")

glimpse(main_df)

#looks ok so I'll download the data into R
main_df <- collect(main_df)

#reloading it (R Studio crashed or new session)
main_df <-read.csv("C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\cleaned_data.csv")


#Visualisations
library(ggplot2)
library(tidyverse)
library(dplyr)
library(scales)
library(tidyr)
##colours
  #member = "#1F84FF"
  #casual = "#0F3D6E"
  #grey = "#CCCCCC"
  #classic = "#0F676D"
  #electric = "#666666"

##Some cleaning for R...I will fix these in SQL later
main_df <- main_df %>%
  mutate(monthly_count_change = if_else(season_number == 1 & is.na(monthly_count_change), 0, monthly_count_change))
##Also there were some medians missing so I'll calculate them here for now...
day_medians_df <- main_df %>%
  group_by(started_at_day, member_casual) %>%
  summarise(day_medians = median(ride_length, na.rm = TRUE))

hour_medians_df <- main_df %>% 
  group_by(started_at_hour, member_casual) %>% 
  summarise(hour_medians = median(ride_length, na.rm = TRUE))

season_day_medians_df <- main_df %>% 
  group_by(season, started_at_day,  member_casual) %>% 
  summarise(season_day_medians = median(ride_length, na.rm = TRUE))

rideable_day_medians_df <- main_df %>%
  group_by(started_at_day, rideable_type, member_casual) %>% 
  summarise(rideable_day_medians = median(ride_length, na.rm = TRUE))

rideable_hour_medians_df <- main_df %>% 
  group_by(started_at_hour, rideable_type, member_casual) %>% 
  summarise(rideable_hour_medians = median(ride_length, na.rm = TRUE))

rideable_day_medians_df <- main_df %>%
  group_by(started_at_day, rideable_type, member_casual) %>% 
  summarise(rideable_day_medians = median(ride_length, na.rm = TRUE))

rideable_day_hour_medians_df <- main_df %>% 
  group_by(started_at_day, started_at_hour, rideable_type, member_casual) %>% 
  summarise(rideable_day_hour_medians = median(ride_length, na.rm = TRUE))

rideable_season_hour_medians_df <- main_df %>% 
  group_by(season, started_at_hour, rideable_type, member_casual) %>% 
  summarise(rideable_season_hour_medians = median(ride_length, na.rm = TRUE))

main_df <- main_df %>%
  left_join(day_medians_df, by = c("started_at_day", "member_casual")) %>%
  left_join(hour_medians_df, by = c("started_at_hour", "member_casual")) %>% 
  left_join(season_day_medians_df, by = c("season", "started_at_day", "member_casual")) %>% 
  left_join(rideable_day_medians_df, by = c("started_at_day", "rideable_type", "member_casual")) %>% 
  left_join(rideable_hour_medians_df, by = c("started_at_hour", "rideable_type", "member_casual")) %>% 
  left_join(rideable_day_hour_medians_df, by = c("started_at_day", "started_at_hour", "rideable_type", "member_casual")) %>% 
  left_join(rideable_season_day_medians_df, by = c("season", "started_at_day", "rideable_type", "member_casual")) %>% 
  left_join(rideable_season_hour_medians_df, by = c("season", "started_at_hour", "rideable_type", "member_casual"))

##Day names were cluttering viz
main_df <- main_df %>% mutate(start_at_dayofweek = recode(start_at_dayofweek,
                                   "Monday" = "M",
                                   "Tuesday" = "T",
                                   "Wednesday" = "W",
                                   "Thursday" = "Th",
                                   "Friday" = "F",
                                   "Saturday" = "Sa",
                                   "Sunday" = "Su"))
##Reorder things so I don't have to use day numbers
###season
main_df$season <- factor(main_df$season, 
                         levels = c("Winter", "Fall", "Spring", "Summer"))
###month
main_df$start_at_month_name <- factor(main_df$start_at_month_name, 
                                      levels = c("January", "February", "March", "April", 
                                                 "May", "June", "July", "August", 
                                                 "September", "October", "November", "December"))
###day
main_df$start_at_dayofweek <- factor(main_df$start_at_dayofweek, 
                                     levels = c("M", "T", "W", "Th", "F", "Sa", "Su"))

#Save data in folder
write.csv(main_df, file = "C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\cleaned_data.csv")

#sample dataset to test as functions take time to run
sample_df <- main_df %>% sample_n(1000)


#are ride lengths normally distributed?
##members
member_ride_lengths <- main_df %>% 
  filter(member_casual == "member") %>% 
  pull(ride_length) %>% 
  as.numeric()

hist(member_ride_lengths, breaks = 1000, main="Histogram of ride_length for members", xlab="ride_length")
#left skewed

##casuals
casual_ride_lengths <- main_df %>% 
  filter(member_casual == "casual") %>% 
  pull(ride_length) %>% 
  as.numeric()

hist(casual_ride_lengths, breaks = 1000, main="Histogram of ride_length for casual", xlab="ride_length")
#left skewed
##this isn't surprising as you can't have negative ride length
##we will later use medians instead of average ride lengths because of this

#Seasonal trends per membership

count_season_plot <- main_df %>%
  group_by(season, member_casual) %>%
  summarise(ride_count = n()) %>%
  ggplot(aes(x = factor(season, levels = c("Winter", "Spring", "Summer", "Fall")), y = ride_count, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = "season")+
  theme_minimal()

count_season_plot


#Monthly change
count_change_plot <- main_df %>%
  group_by(start_at_month_name, member_casual) %>%
  ggplot(aes(x = reorder(start_at_month_name, started_at_month), y = monthly_count_change, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL, y = "monthly % change")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

count_change_plot

#daily trends
count_day_plot <- main_df %>%
  group_by(start_at_dayofweek, started_at_day, member_casual) %>%
  summarise(ride_count = n()) %>% 
  ggplot(aes(x = reorder(start_at_dayofweek, started_at_day), y = ride_count, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL) +
  theme_minimal()+
  scale_y_continuous(labels = comma)

count_day_plot

#seasonal daily count

data_summary <- main_df %>%
  group_by(start_at_dayofweek, started_at_day, season, member_casual) %>%
  summarize(count = n()) %>%
  ungroup()


count_day_season <- ggplot(data_summary, aes(x = reorder(start_at_dayofweek, started_at_day), y = count, color = member_casual)) +
  geom_line(aes(group = member_casual)) +
  labs(x = NULL,
       y = "ride_count") +
  facet_wrap(~season, ncol = 4) +
  scale_color_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal()

count_day_season

#hourly trends
count_hour_plot <- main_df %>%
  group_by(started_at_hour, member_casual) %>%
  summarise(ride_count = n()) %>% 
  ggplot(aes( x = started_at_hour, y = ride_count, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL) +
  theme_minimal()+
  scale_y_continuous(labels = comma)

count_hour_plot

#seasonal hourly count

data_summary <- main_df %>%
  group_by(season, started_at_hour, member_casual) %>%
  summarize(count = n()) %>%
  ungroup()


count_hour_season <- ggplot(data_summary, aes(x = started_at_hour, y = count, color = member_casual)) +
  geom_line(aes(group = member_casual)) +
  labs(
       x = NULL,
       y = "ride_count",
       color = "Rider Type") +
  facet_wrap(~season, ncol = 4) +
  scale_color_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal()

count_hour_season

#daily hour count
data_summary <- main_df %>%
  select(started_at_day, start_at_dayofweek, started_at_hour, member_casual) %>% 
  group_by(member_casual, started_at_day, start_at_dayofweek, started_at_hour) %>%
  summarize(count = n()) %>%
  ungroup()


count_hour_day <- ggplot(data_summary, aes(x = started_at_hour, y = count, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  labs(
    x = NULL,
    y = "ride_count",
    color = "Rider Type") +
  facet_wrap(~reorder(start_at_dayofweek, started_at_day), ncol = 7) +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal()

count_hour_day

#Classic bike vs electric bike
count_type_plot <- main_df %>%
  group_by(rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ggplot(aes(x = member_casual, y = ride_count, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  theme_minimal() +
  labs(x = NULL)

count_type_plot

#type  seasonal

count_type_season <- main_df %>%
  group_by(season, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ggplot(aes(x = member_casual, y = ride_count, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  facet_wrap(~season, ncol = 4) +
  labs(x = NULL) +
  theme_minimal() +
  scale_y_continuous(labels = comma)+
  theme(axis.text.x = element_blank())


count_type_season

#type day

count_type_day <- main_df %>%
  group_by(start_at_dayofweek, started_at_day, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ggplot(aes(x = member_casual, y = ride_count, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  facet_wrap(~reorder(start_at_dayofweek, started_at_day), ncol = 7) +
  labs(x = NULL) +
  theme_minimal() +
  scale_y_continuous(labels = comma) +
  theme(axis.text.x = element_blank(),strip.text = element_text(size = 16))


count_type_day

###Diff per day
##gotta calculate the diff first
rideable_day_count_diff <- main_df %>%
  group_by(start_at_dayofweek, started_at_day, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ungroup() %>% 
  select(member_casual, rideable_type, started_at_day, start_at_dayofweek, ride_count) %>%
  arrange(started_at_day, member_casual, rideable_type) %>% 
  mutate(diff = ride_count - lead(ride_count)) %>%
  mutate(diff_pct = 100*(diff/lead(ride_count))) %>%
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, start_at_dayofweek, started_at_day, diff_pct)


##now plot  
rideable_day_count_diff_plot <- rideable_day_count_diff %>% 
  ggplot( aes(x = reorder(start_at_dayofweek, started_at_day), y = diff_pct, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  labs(
    x = NULL,
    y = "count difference (%)",
    color = "membership") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal()+
  theme(axis.text = element_text(size = 14))

rideable_day_count_diff_plot
###change per season_day?
##gotta calculate the diff first
rideable_season_day_count_diff <- main_df %>%
  group_by(season, season_number, start_at_dayofweek, started_at_day, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ungroup() %>% 
  select(member_casual, rideable_type, season, season_number, started_at_day, start_at_dayofweek, ride_count) %>%
  arrange(season_number, started_at_day, member_casual, rideable_type) %>% 
  mutate(diff = ride_count - lead(ride_count)) %>%
  mutate(diff_pct = 100*(diff/lead(ride_count))) %>%
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, season, season_number, start_at_dayofweek, started_at_day, diff_pct)


##now plot  
rideable_season_day_count_diff_plot <- rideable_season_day_count_diff %>% 
  ggplot( aes(x = reorder(start_at_dayofweek, started_at_day), y = diff_pct, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  labs(
    x = NULL,
    y = "count difference (%)",
    color = "membership") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  facet_wrap(~reorder(season, season_number))+
  theme_minimal()+
  theme(axis.text = element_text(size = 14))

rideable_season_day_count_diff_plot

###Does this daily trend change per month?
rideable_day_month_count_diff <- main_df %>%
  group_by(started_at_month, start_at_month_name, start_at_dayofweek, started_at_day, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ungroup() %>% 
  select(started_at_month, start_at_month_name, member_casual, rideable_type, started_at_day, start_at_dayofweek, ride_count) %>%
  arrange(started_at_month, started_at_day, member_casual, rideable_type) %>% 
  mutate(diff = ride_count - lead(ride_count)) %>%
  mutate(diff_pct = 100*(diff/lead(ride_count))) %>% 
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, started_at_month, start_at_month_name, start_at_dayofweek, started_at_day, diff_pct)

rideable_day_month_count_diff_plot <- rideable_day_month_count_diff %>% 
  ggplot(aes(x = reorder(start_at_dayofweek, started_at_day), y = diff_pct, color = member_casual)) +
  geom_line(aes(group = member_casual)) +
  labs(
    x = NULL,
    y = "count difference (%)",
    color = "membership") +
  scale_color_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  facet_wrap(~factor(start_at_month_name, levels = c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")), ncol = 4) +
  theme_minimal()

rideable_day_month_count_diff_plot


#type hour

count_type_hour <- main_df %>%
  group_by(started_at_hour, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>% 
  ggplot(aes(x = member_casual, y = ride_count, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  facet_wrap(~started_at_hour, ncol = 4) +
  labs(x = NULL) +
  theme_minimal() +
  scale_y_continuous(labels = comma) +
  theme(axis.text.x = element_blank())


count_type_hour

###there seems to be a preference for electric bikes for casuals early in the morning
count_type_hour_morning <- main_df %>%
  filter(started_at_hour %in% c(4, 5, 6, 7, 8)) %>%
  group_by(started_at_hour, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ggplot(aes(x = member_casual, y = ride_count, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  facet_wrap(~started_at_hour, ncol = 3) +
  labs(x = NULL) +
  theme_minimal() +
  scale_y_continuous(labels = comma)+
  theme(axis.text.x = element_blank())

count_type_hour_morning

###Type Season hour
rideable_season_hour_count_diff <- main_df %>%
  select(member_casual, rideable_type, season, season_number, started_at_hour) %>%
  group_by(season, season_number, started_at_hour, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ungroup() %>% 
  arrange(season, started_at_hour, member_casual, rideable_type) %>% 
  mutate(diff = ride_count - lead(ride_count)) %>%
  mutate(diff_pct = 100*(diff/lead(ride_count))) %>%
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, season, season_number, started_at_hour, diff_pct)

rideable_season_hour_count_diff <- rideable_season_hour_count_diff %>%
  ggplot(aes(x = started_at_hour, y = diff_pct, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  facet_wrap(~reorder(season, season_number), ncol = 4) +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL, y = "rideable difference (%)") +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), strip.text = element_text(size = 16), axis.text.y = element_text(size = 14))

rideable_season_hour_count_diff_plot

###Type day hour
rideable_day_hour_count_diff <- main_df %>%
  select(member_casual, rideable_type, started_at_day, start_at_dayofweek, started_at_hour) %>%
  group_by(started_at_day, start_at_dayofweek, started_at_hour, rideable_type, member_casual) %>%
  summarise(ride_count = n()) %>%
  ungroup() %>% 
  arrange(started_at_day, started_at_hour, member_casual, rideable_type) %>% 
  mutate(diff = ride_count - lead(ride_count)) %>%
  mutate(diff_pct = 100*(diff/lead(ride_count))) %>%
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, started_at_day, start_at_dayofweek, started_at_hour, diff_pct)

rideable_day_hour_count_diff <- rideable_day_hour_count_diff %>%
  ggplot(aes(x = started_at_hour, y = diff_pct, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  facet_wrap(~reorder(start_at_dayofweek, started_at_day), ncol = 7) +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL, y = "rideable difference (%)") +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), strip.text = element_text(size = 16), axis.text.y = element_text(size = 14))

rideable_day_hour_count_diff



#                         Median ride length

##median seasonal
median_season <- main_df %>%
  select(season, seasonal_medians, member_casual) %>% 
  distinct(season, member_casual, .keep_all = TRUE) %>% 
  ggplot(aes(x = season, y = seasonal_medians, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL) +
  theme_minimal()

median_season

##median change
median_change <- main_df %>%
  distinct(start_at_month_name, member_casual, .keep_all = TRUE) %>% 
  ggplot(aes(x = reorder(start_at_month_name, started_at_month), y = monthly_length_change, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL, y = "monthly % change")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

median_change


##daily median trends
median_day <- main_df %>%
  select(start_at_dayofweek, member_casual, day_medians) %>%
  distinct(start_at_dayofweek, member_casual, .keep_all = TRUE) %>%
  ggplot(aes(x = start_at_dayofweek, y = day_medians, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL) +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), axis.text.y = element_text(size = 14))


median_day

##seasonal daily median
median_day_season <- main_df %>% 
  select(start_at_dayofweek, started_at_day, season, season_day_medians, member_casual) %>% 
  distinct(season, start_at_dayofweek, member_casual, .keep_all = TRUE) %>% 
  ggplot( aes(x = reorder(start_at_dayofweek, started_at_day), y = season_day_medians, color = member_casual)) +
  geom_line(aes(group = member_casual)) +
  labs(
    x = NULL,
    y = "median length",
    color = "Rider Type") +
  facet_wrap(~season, ncol = 4) +
  scale_color_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), axis.text.y = element_text(size = 14), strip.text = element_text(size = 16))


median_day_season

##hourly median trends
median_hour <- main_df %>%
  select(started_at_hour, hour_medians, member_casual) %>%
  distinct(started_at_hour, member_casual, .keep_all = TRUE) %>%
  ggplot(aes(x = started_at_hour, y = hour_medians, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL) +
  theme_minimal()

median_hour

##daily hourly trends
median_hour_day <- main_df %>%
  select(started_at_hour, day_hour_medians, member_casual, start_at_dayofweek, started_at_day) %>%
  distinct(start_at_dayofweek, started_at_hour, member_casual, .keep_all = TRUE) %>% 
  ggplot(aes(x = started_at_hour, y = day_hour_medians, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  facet_wrap(~factor(start_at_dayofweek,levels = c("Monday" = "M",
                     "Tuesday" = "T",
                     "Wednesday" = "W",
                     "Thursday" = "Th",
                     "Friday" = "F",
                     "Saturday" = "Sa",
                     "Sunday" = "Su")), ncol = 7) +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL) +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), strip.text = element_text(size = 16))

median_hour_day

##Median Classic vs electric

median_type <- main_df %>%
  select(rideable_type, member_casual, ride_length) %>% 
  group_by(rideable_type, member_casual) %>%
  summarise(median_ride_length = median(ride_length, na.rm = TRUE)) %>% 
  ggplot(aes(x = member_casual, y = median_ride_length, fill = rideable_type)) + 
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  theme_minimal() +
  labs(x = NULL)

median_type
###Month
median_type_month <- main_df %>%
  select(start_at_month_name, rideable_month_medians, rideable_type, member_casual) %>% 
  group_by(start_at_month_name, rideable_month_medians, rideable_type, member_casual) %>%
  distinct(start_at_month_name, rideable_type, member_casual, .keep_all = TRUE) %>% 
  ggplot(aes(x = member_casual, y = rideable_month_medians, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  facet_wrap(~factor(start_at_month_name, levels = c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")), ncol = 4) +
  labs(x = NULL, caption = "Note: Left bars = casual, Right bars = member") +
  theme_minimal() +
  scale_y_continuous(labels = comma) +
  theme(axis.text.x = element_blank())

median_type_month

###Diff per Month
##gotta calculate the diff first
rideable_month_medians_diff <- main_df %>%
  select(member_casual, rideable_type, started_at_month, start_at_month_name, rideable_month_medians) %>%
  distinct(member_casual, rideable_type, started_at_month, .keep_all = TRUE) %>%
  arrange(started_at_month, member_casual, rideable_type) %>%
  mutate(diff = rideable_month_medians - lead(rideable_month_medians)) %>%
  mutate(diff_pct = 100*(diff/lead(rideable_month_medians))) %>% 
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, started_at_month, start_at_month_name, diff_pct)
  
  ##now plot  
rideable_month_medians_diff_plot <- rideable_month_medians_diff %>% 
  ggplot( aes(x = reorder(start_at_month_name, started_at_month), y = diff_pct, color = member_casual)) +
  geom_line(aes(group = member_casual)) +
  labs(
    x = NULL,
    y = "median difference (%)",
    color = "membership") +
  scale_color_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 15))

rideable_month_medians_diff_plot

###day
median_type_day <- main_df %>%
  distinct(start_at_dayofweek, rideable_month_day_medians, rideable_type, member_casual) %>%
  ggplot(aes(x = member_casual, y = rideable_month_day_medians, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  facet_wrap(~factor(start_at_dayofweek, levels = c("Monday" = "M",
                                                    "Tuesday" = "T",
                                                    "Wednesday" = "W",
                                                    "Thursday" = "Th",
                                                    "Friday" = "F",
                                                    "Saturday" = "Sa",
                                                    "Sunday" = "Su")), ncol = 7) +
  labs(x = NULL, caption = "Note: Left bar = casual, Right bar = member") +
  theme_minimal() +
  scale_y_continuous(labels = comma) +
  theme(axis.text.x = element_blank())

median_type_day

###is there a trend in difference?
rideable_day_medians_diff <- main_df %>%
  select(member_casual, rideable_type, started_at_day, start_at_dayofweek, rideable_day_medians) %>%
  distinct(member_casual, rideable_type, started_at_day, .keep_all = TRUE) %>%
  arrange(started_at_day, member_casual, rideable_type) %>%
  mutate(diff = rideable_day_medians - lead(rideable_day_medians)) %>%
  mutate(diff_pct = 100*(diff/lead(rideable_day_medians))) %>% 
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, started_at_day, start_at_dayofweek, diff_pct)


##now plot  
rideable_day_medians_diff_plot <- rideable_day_medians_diff %>% 
  ggplot( aes(x = reorder(start_at_dayofweek, started_at_day), y = diff_pct, color = member_casual)) +
  geom_line(aes(group = member_casual)) +
  labs(
    x = "day",
    y = "median difference (%)",
    color = "membership") +
  scale_color_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), axis.text.y = element_text(size = 14))


rideable_day_medians_diff_plot

###hour
median_type_hour_bar <- main_df %>%
  select(started_at_hour, rideable_day_hour_medians, rideable_type, member_casual) %>%
  distinct(started_at_hour, rideable_type, member_casual, .keep_all = TRUE) %>% 
  ggplot(aes(x = member_casual, y = rideable_day_hour_medians, fill = rideable_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c(classic_bike = "#0F676D", electric_bike = "#666666")) +
  facet_wrap(~started_at_hour, ncol = 47) +
  labs(x = NULL, caption = "Note: Left bar = casual, Right bar = member") +
  theme_minimal() +
  scale_y_continuous(labels = comma) +
  theme(axis.text.x = element_blank())

median_type_hour_bar

###There seems to be some trends. Let's clarify
###Diff per hour
##gotta calculate the diff first
rideable_hour_medians_diff <- main_df %>%
  select(member_casual, rideable_type, started_at_hour, rideable_hour_medians) %>%
  distinct(member_casual, rideable_type, started_at_hour, .keep_all = TRUE) %>%
  arrange(started_at_hour, member_casual, rideable_type) %>%
  mutate(diff = rideable_hour_medians - lead(rideable_hour_medians)) %>%
  mutate(diff_pct = 100*(diff/lead(rideable_hour_medians))) %>% 
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, started_at_hour, diff_pct)

##now plot  
rideable_hour_medians_diff_plot <- rideable_hour_medians_diff %>% 
  ggplot(aes(x = as.factor(started_at_hour), y = diff_pct, color = member_casual)) +
  geom_line(aes(group = member_casual)) +
  labs(
    x = "hour",
    y = "median difference (%)",
    color = "membership") +
  scale_color_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  theme_minimal() +
  theme(axis.text.x = element_text(size = 12), strip.text = element_text(size = 16) )

rideable_hour_medians_diff_plot

###does this differ depending on the day or month?
rideable_day_hour_medians_diff <- main_df %>%
  select(member_casual, rideable_type, started_at_day, start_at_dayofweek, started_at_hour, rideable_day_hour_medians.x) %>%
  distinct(member_casual, rideable_type, started_at_day, started_at_hour, .keep_all = TRUE) %>%
  arrange(started_at_day, started_at_hour, member_casual, rideable_type) %>%
  mutate(diff = rideable_day_hour_medians.x - lead(rideable_day_hour_medians.x)) %>%
  mutate(diff_pct = 100*(diff/lead(rideable_day_hour_medians.x))) %>% 
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, started_at_day, start_at_dayofweek, started_at_hour, diff_pct)
###Plot
rideable_day_hour <- rideable_day_hour_medians_diff %>%

  ggplot(aes(x = factor(started_at_hour), y = diff_pct, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  facet_wrap(~factor(start_at_dayofweek,levels = c("Monday" = "M",
                                                   "Tuesday" = "T",
                                                   "Wednesday" = "W",
                                                   "Thursday" = "Th",
                                                   "Friday" = "F",
                                                   "Saturday" = "Sa",
                                                   "Sunday" = "Su")), ncol = 2) +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL, y = "rideable difference (%)") +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), strip.text = element_text(size = 16))

rideable_day_hour

###not much but what about season?
rideable_season_hour_medians_diff <- main_df %>%
  select(member_casual, rideable_type, season_number, season, started_at_hour, rideable_season_hour_medians) %>%
  distinct(member_casual, rideable_type, season, started_at_hour, .keep_all = TRUE) %>%
  arrange(season_number, started_at_hour, member_casual, rideable_type) %>%
  mutate(diff = rideable_season_hour_medians - lead(rideable_season_hour_medians)) %>%
  mutate(diff_pct = 100*(diff/lead(rideable_season_hour_medians))) %>% 
  filter(rideable_type == "classic_bike") %>%
  select(member_casual, season, season_number, started_at_hour, diff_pct)
###Plot
rideable_season_hour <- rideable_season_hour_medians_diff %>%
  ggplot(aes(x = started_at_hour, y = diff_pct, fill = member_casual)) +
  geom_area(aes(group = member_casual), position = "identity", alpha = 0.7) +
  facet_wrap(~reorder(season, season_number), ncol = 4) +
  scale_fill_manual(values = c(member = "#1F84FF", casual = "#0F3D6E")) +
  labs(x = NULL, y = "rideable difference (%)") +
  theme_minimal()+
  theme(axis.text.x = element_text(size = 14), strip.text = element_text(size = 16), axis.text.y = element_text(size = 14))

rideable_season_hour

###is there a correlation between the count and medians?

season_hour_corr_df <- rideable_season_hour_count_diff %>% 
  left_join(rideable_season_hour_medians_diff, by = c("season", "started_at_hour", "member_casual"))

season_hour_corr_df %>%
ggplot( aes(x=diff_pct.x, y=diff_pct.y)) +
  geom_point() +
  geom_smooth(method="lm") +
  labs(title="Scatterplot of diff_pct.x vs diff_pct.y", 
       x="diff_pct.x", y="diff_pct.y")
####nope


#map
#connecting to bigquery to pull the data

library(bigrquery)
library(dplyr)
df <- dbConnect(
  bigquery(),
  project =  "japanese-grammar-276308",
  dataset = "divvy_project_mana",
  billing = "japanese-grammar-276308"
)

#checking if we got the tables
dbListTables(df)


#some more testing...
map_df <- tbl(df, "member_route_all")

glimpse(map_df)

#looks ok so I'll download the data into R
map_df <- collect(map_df)

#Save data in folder
write.csv(map_df, file = "C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\route_all.csv")
#reloading
map_df <- read.csv("C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\route_all.csv")

library(ggmap)
ggmap::register_google(key = "API REMOVED FOR SECURITY")
###obtain base map

base_map <- get_map(location = c(lon = median(map_df$start_lng_round), lat = median(map_df$start_lat_round)), 
                    zoom = 12, maptype = "terrain-lines", source = "stamen")

###Plot on map
geomap <- ggmap(base_map) + 
  geom_point(data = map_df, aes(x = start_lng_round, y = start_lat_round, color = member_casual, alpha = 0.5, size = num_occurrences), 
              position = "jitter") + 
  scale_color_manual(values = c("member" = "#1F84FF", "casual" = "#0F3D6E")) +
  scale_size(range = c(5, 10)) +
  guides(alpha = FALSE, size = FALSE) +
  theme_minimal() +
  theme(legend.text = (element_text(size = 16))) +
  labs(title = "Top 10 start stations",
       x = "Longitude", y = "Latitude")
geomap
ggsave(filename = "C:\\Users\\Mana\\Documents\\R\\cyclistic\\images\\map_start.png", plot = geomap, width = 4, height = 6, dpi = 300)

###repeat for end station

###Plot on map
geomap_end <- ggmap(base_map) + 
  geom_point(data = map_df, aes(x = end_lng_round, y = end_lat_round, color = member_casual, alpha = 0.5, size = num_occurrences), 
             position = "jitter") + 
  scale_color_manual(values = c("member" = "#1F84FF", "casual" = "#0F3D6E")) +
  scale_size(range = c(5, 10)) +
  guides(alpha = FALSE, size = FALSE) +
  theme_minimal() +
  theme(legend.text = (element_text(size = 16))) +
  labs(title = "Top 10 end stations",
       x = "Longitude", y = "Latitude")
geomap_end

### flow map
base_map_flow <-  get_map(location = c(lon = -87.6, lat = 41.83), 
                          zoom = 12, maptype = "terrain-lines")

flow_map <- ggmap(base_map_flow) + 
  geom_segment(data = map_df,
               aes(x = start_lng_round, y = start_lat_round,
                   xend = end_lng_round, yend = end_lat_round,
                   color = member_casual, alpha = 0.5)
               ) +
  scale_size_continuous(range = c(1, 5)) +
  scale_color_manual(values = c("member" = "#1F84FF", "casual" = "#0F3D6E")) +
  theme_minimal() +
  labs(title = "Popular rides",
       x = "Longitude", y = "Latitude")

flow_map

###testing hypothesis for lunch time casual median length increase
library(bigrquery)
library(dplyr)
df <- dbConnect(
  bigquery(),
  project =  "japanese-grammar-276308",
  dataset = "divvy_project_mana",
  billing = "japanese-grammar-276308"
)

#checking if we got the tables
dbListTables(df)


#some more testing...
map_lunch_df <- tbl(df, "member_route_lunch")

glimpse(map_lunch_df)

#looks ok so I'll download the data into R
map_lunch_df <- collect(map_lunch_df)

#Save data in folder
write.csv(map_lunch_df, file = "C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\route_lunch.csv")
# load again
map_lunch_df <- read.csv("C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\route_lunch.csv")

library(ggmap)
ggmap::register_google(key = "AIzaSyD6ACi8YAkscQplip8x2FZMG2dBI3DHC5M")

###only need casuals
map_lunch_casual <- map_lunch_df %>% 
                    filter(member_casual == "casual")
###obtain base map
base_lunch_map <-  get_map(location = c(lon = median(map_lunch_casual$start_lng_round), lat = median(map_lunch_casual$start_lat_round)), 
                     zoom = 14, maptype = "terrain-lines")

###flow map 
lunch_flow_map <- ggmap(base_lunch_map) + 
  geom_segment(data = map_lunch_casual,
               aes(x = start_lng_round, y = start_lat_round,
                   xend = end_lng_round, yend = end_lat_round,
                   color = member_casual, alpha = 0.5)
  ) +
  scale_size_continuous(range = c(1, 5)) +
  scale_color_manual(values = c("member" = "#1F84FF", "casual" = "#0F3D6E")) +
  theme_minimal() +
  labs(title = "Popular casual rides 1-2PM",
       x = "Longitude", y = "Latitude")

lunch_flow_map


#Checking the reason for 5AM classical ride length spikes for members
###testing hypothesis for lunch time casual median length increase
library(bigrquery)
library(dplyr)
df <- dbConnect(
  bigquery(),
  project =  "japanese-grammar-276308",
  dataset = "divvy_project_mana",
  billing = "japanese-grammar-276308"
)

#checking if we got the tables
dbListTables(df)

fiveAM_df <- tbl(df, "5AMmembers")

glimpse(fiveAM_df)

#looks ok so I'll download the data into R
fiveAM_df <- collect(fiveAM_df)

#Save data in folder
write.csv(fiveAM_df, file = "C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\fiveAM_df.csv")
# load again if necesary
map_lunch_df <- read.csv("C:\\Users\\Mana\\Documents\\R\\cyclistic\\Data_R\\fiveAM_df.csv")

### flow map
base_map_flow <-  get_map(location = c(lon = median(fiveAM_df$start_lng_round), lat = median(fiveAM_df$start_lat_round)), 
                          zoom = 12, maptype = "terrain-lines")

geomap <- ggmap(base_map) + 
  geom_point(data = fiveAM_df, aes(x = start_lng_round, y = start_lat_round, alpha = 0.3, color = "orange"), 
             position = "jitter") + 
  geom_point(data = fiveAM_df, aes(x = end_lng_round, y = end_lat_round, alpha = 0.5, color = "green" ), 
             position = "jitter") + 
  scale_size(range = c(5, 10)) +
  guides(alpha = FALSE, size = FALSE) +
  theme_minimal() +
  theme(legend.position = "none" ) +
  labs(title = "5 AM member rides start station",
       x = "Longitude", y = "Latitude")
geomap
