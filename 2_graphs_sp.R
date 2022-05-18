# Graphs
# Emilio Lehoucq

# Loading libraries -------------------------------------------------------

library(tidyverse)
library(caret)
library(lubridate)

# Reading data ------------------------------------------------------------

data <- readRDS("Data/sp500.rds")

# Creating day average ----------------------------------------------------

data <- mutate(data, daily_average = (low + high) / 2)

# Aggregating by month ----------------------------------------------------

data$date <- floor_date(data$date, "month")

# Shortening sector names -------------------------------------------------

data <- data %>% 
  mutate(sector = replace(sector, sector == "Communication Services", "Communications"),
         sector = replace(sector, sector == "Consumer Discretionary", "C. Discretionary"),
         sector = replace(sector, sector == "Information Technology", "IT"))

# Plotting price trajectory across sectors --------------------------------

table(data$sector)
length(table(data$sector)) # 11 sectors

range(data$date)
length(table(data$date)) # 61 dates

sum(is.na(data$sector))

pdf("sector_prices_over_time.pdf") 
data %>% 
  filter(!is.na(sector)) %>% 
  group_by(sector, date) %>% 
  summarise(mean_daily_average = mean(daily_average, na.rm = TRUE)) %>% 
  ggplot() +
  geom_line() +
  aes(date, mean_daily_average) +
  theme_bw() +
  theme(panel.border = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  xlab("Date (aggregated monthly)") +
  ylab("Average stock price") +
  facet_wrap(~ sector) +
  ggtitle("Change in S&P 500 stock prices 2013-2018")
dev.off() 

# Plotting price trajectory across companies ------------------------------

table(data$company_name)
sum(is.na(data$company_name))

grouped_by_company <- data %>% 
  filter(!is.na(company_name)) %>% 
  group_by(company_name, date) %>% 
  summarise(mean_daily_average = mean(daily_average, na.rm = TRUE))

for (i in c(1:length(unique(grouped_by_company$company_name)))) {
  
    plot <- grouped_by_company %>% 
    filter(company_name == unique(grouped_by_company$company_name)[i]) %>% 
    ggplot() +
    geom_line() +
    aes(date, mean_daily_average) +
    theme_bw() +
    theme(panel.border = element_blank(),
          plot.title = element_text(hjust = 0.5)) +
    xlab("Date (aggregated monthly)") +
    ylab("Average stock price") +
    ggtitle(unique(grouped_by_company$company_name)[i])
  
    ggsave(plot, file = paste0("individual_stocks/", unique(grouped_by_company$company_name)[i],".png"), width = 14, height = 10, units = "cm")
    
}
