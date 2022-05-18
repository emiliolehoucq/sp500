# Descriptive analyses
# Emilio Lehoucq

# Loading libraries -------------------------------------------------------

library(tidyverse)
library(caret)
library(lubridate)

# Reading data ------------------------------------------------------------

data <- readRDS("Data/sp500.rds")

# Exploring observations per company --------------------------------------

min(table(data$company_name))
max(table(data$company_name))
# between 44 and 1259 observations for each of the 418 companies

table(data$company_name)[table(data$company_name) < 500]
length(table(data$company_name)[table(data$company_name) < 500]) # 5 companies with less than 500 observations

# Dropping data for companies with less than 500 observations -------------

data <- filter(data, !company_name %in% c("Aptiv", "DXC Technology", "Fortive", "Hilton Worldwide", "Under Armour (Class C)")) # n = 617,637 (dropped 1403 rows)
# kept 413 companies

# Creating day average ----------------------------------------------------

data <- mutate(data, daily_average = (low + high) / 2)

# Shortening sector names -------------------------------------------------

data <- data %>% 
  mutate(sector = replace(sector, sector == "Communication Services", "Communications"),
         sector = replace(sector, sector == "Consumer Discretionary", "C. Discretionary"),
         sector = replace(sector, sector == "Information Technology", "IT"))

# Multiples ---------------------------------------------------------------

min(data$date) # "2013-02-08"
max(data$date) # 2018-02-07"

first_date <- data %>% filter(date == "2013-02-08") %>% select(company_name, sector, daily_average) # n = 476
last_date <- data %>% filter(date == "2018-02-07") %>% select(company_name, sector, daily_average) # n = 500

first_date %>% 
  inner_join(last_date, by = "company_name") %>% 
  na.omit() %>%  # n = 396 
  rename(initial_date = daily_average.x,
         final_date = daily_average.y,
         sector = sector.x) %>% 
  mutate(multiple = final_date / initial_date) %>%
  filter(multiple >= 5)
# 1 Adobe                         IT                      38.8  IT                    194.      5.00
# 2 Align Technology              Health Care             32.6  Health Care           238.      7.29
# 3 Amazon                        C. Discretionary       263.   C. Discretionary     1438.      5.47
# 4 Activision Blizzard           Communications          13.4  Communications         70.1     5.23
# 5 Broadcom                      IT                      35.3  IT                    240.      6.80
# 6 Electronic Arts               Communications          17.2  Communications        124.      7.19
# 7 Facebook                      Communications          28.8  Communications        183.      6.33
# 8 Huntington Ingalls Industries Industrials             45.0  Industrials           233.      5.18
# 9 Southwest Airlines            Industrials             11.6  Industrials            58.5     5.03
# 10 Micron Technology             IT                       7.74 IT                     42.7     5.51
# 11 Netflix                       Communications          26.0  Communications        268.     10.3 
# 12 Northrop Grumman              Industrials             65.9  Industrials           334.      5.07
# 13 Nvidia                        IT                      12.4  IT                    231.     18.6 
# 14 Constellation Brands          Consumer Staples        32.0  Consumer Staples      216.      6.74

first_date %>% 
  inner_join(last_date, by = "company_name") %>% 
  na.omit() %>%  # n = 396 
  rename(initial_date = daily_average.x,
         final_date = daily_average.y,
         sector = sector.x) %>% 
  mutate(multiple = final_date / initial_date) %>%
  arrange(multiple) %>% 
  print(n=20)

first_date %>% 
  inner_join(last_date, by = "company_name") %>% 
  na.omit() %>%  # n = 396 
  rename(initial_date = daily_average.x,
         final_date = daily_average.y,
         sector = sector.x) %>% 
  mutate(multiple = final_date / initial_date) %>%
  filter(between(multiple, 1.5, 2.5)) %>% 
  print(n=20)

pdf("multiples.pdf") 
first_date %>% 
  inner_join(last_date, by = "company_name") %>% 
  na.omit() %>%  # n = 396 
  rename(initial_date = daily_average.x,
         final_date = daily_average.y,
         sector = sector.x) %>% 
  mutate(multiple = if_else(final_date / initial_date >= 5, 5, final_date / initial_date)) %>% 
  ggplot() +
  geom_histogram(aes(x = multiple, y = ((..count..)/ length(na.omit(unique(data$company_name))) * 100), fill = sector)) +
  theme_bw() +
  theme(panel.border = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  xlab("Multiple (last price / initial price)") +
  ylab("Percentage of companies") +
  ggtitle("Change in stock prices by sector in S&P 500 2013-2018") +
  annotate("text", label = "Nvidia", x = 5, y = 4.5, angle = 90, size = 4) +
  annotate("text", label = "IBM", x = 0.768, y = 4, angle = 90, size = 4)+
  annotate("text", label = "Apple", x = 2.38, y = 6, angle = 90, size = 4) +
  guides(fill=guide_legend(title="Sector")) +
  labs(caption = "Companies with multiples higher or equal to 5 (14 companies) changed to 5 for clearer
       visualization. Companies with multiples lower than 1 have gone down.") +
  geom_vline(xintercept = 1)
dev.off()

# Aggregating by month ----------------------------------------------------

data$date <- floor_date(data$date, "month")

# Companies per sector ----------------------------------------------------

pdf("companies_by_sector.pdf") 
data %>% 
  group_by(sector) %>% 
  filter(!is.na(sector)) %>% 
  summarise(companies = n_distinct(company_name)) %>% 
  mutate(proportion = companies * 100 / sum(companies)) %>% 
  ggplot() +
  geom_col(aes(x = fct_reorder(sector, proportion), y = proportion)) +
  coord_flip() +
  theme_bw() +
  theme(panel.border = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  xlab("Sector") +
  ylab("Percentage of companies") +
  ggtitle("Companies by sector in S&P 500 2013-2018")
dev.off()

# Descriptive regressions to get rate of change per stock -----------------

sum(is.na(data$company_name))

data <- data %>% 
  filter(!is.na(company_name)) %>% 
  filter(!is.na(daily_average)) 

results <- tibble(company_name = character(),
                  sector = character(),
                  rate_of_change = numeric())

for (i in c(1:length(na.omit(unique(data$company_name))))) {
  
  linear <- lm(daily_average ~ date, data[ data$company_name == na.omit(unique(data$company_name))[i], ])
  results[i, 1] <- unique(data$company_name)[i]
  results[i, 2] <- data %>% filter(company_name == na.omit(unique(data$company_name))[i]) %>% pull(sector) %>% pluck(1)
  results[i, 3] <- linear$coefficients[2] 

}

results[ results$rate_of_change == min(results$rate_of_change), ] # Chipotle Mexican Grill C. Discretionary        -0.0784
results[ results$rate_of_change == max(results$rate_of_change), ] # Amazon       C. Discretionary          0.503
results[ results$rate_of_change == median(results$rate_of_change), ] # Sempra Energy Utilities         0.0156
results[ 0.01 < results$rate_of_change & results$rate_of_change < 0.02, ] %>% arrange(rate_of_change) %>% print(n=Inf)
results[results$company_name == "American Airlines Group", 3] # 0.0152
results[ results$rate_of_change == quantile(results$rate_of_change, 0.25), ] # McKesson Corporation Health Care        0.00551
results[ -0.1 < results$rate_of_change & results$rate_of_change < 0.001, ] %>% arrange(rate_of_change) %>% print(n=Inf)
results[results$company_name == "IBM", 3] #-0.0275
results[ results$rate_of_change == quantile(results$rate_of_change, 0.75), ] # Texas Instruments IT             0.0320
results[ -0.03 < results$rate_of_change & results$rate_of_change < 0.035, ] %>% arrange(rate_of_change) %>% print(n=Inf)
results[results$company_name == "Salesforce", 3] # 0.0304

pdf("rates_of_change.pdf") 
results %>% #  mutate(rate_of_change = ifelse(rate_of_change > 0.15, 0.15, rate_of_change)) %>% 
  ggplot() +
  geom_histogram(aes(x = rate_of_change, y = ((..count..)/ length(na.omit(unique(data$company_name))) * 100), fill = sector)) +
  labs(title = "Change in S&P 500 stock prices 2013-2018",
       caption = "This is the way to interpret rates of change: on average, the price of a stock changed by X
       dollars per month. For example: on average, the price of Amazon increased by 0.5 dollars per
       month between 2013 and 2018.") +
  ylab("Percentage of companies") +
  xlab("Monthly rate of change") +
  theme_bw() +
  theme(panel.border = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  guides(fill=guide_legend(title="Sector")) +
  geom_vline(xintercept = 0) +
  annotate("text", label = "Chipotle Mexican Grill", x = -0.0784, y = 6, angle = 90, size = 4) +
  annotate("text", label = "Amazon", x = 0.503, y = 4, angle = 90, size = 4) +
  annotate("text", label = "American Airlines Group", x = 0.0152, y = 17, angle = 90, size = 4) +
  annotate("text", label = "IBM", x = -0.0275, y = 6, angle = 90, size = 4) +
  annotate("text", label = "Salesforce", x =  0.0304, y = 10, angle = 90, size = 4) 
dev.off() 

# Volatility --------------------------------------------------------------

# Range -------------------------------------------------------------------

data %>%
  group_by(company_name) %>%
  mutate(range_price = max(daily_average, na.rm = T) - min(daily_average, na.rm = T)) %>% 
  select(range_price) %>% 
  distinct() %>% 
  filter( company_name == "IBM" )

pdf("range.pdf") 
data %>%
  group_by(company_name) %>%
  mutate(range_price = max(daily_average, na.rm = T) - min(daily_average, na.rm = T)) %>% 
  select(range_price) %>% 
  distinct() %>% 
  ggplot() +
  geom_histogram(aes(x = range_price, ((..count..)/ length(na.omit(unique(data$company_name))) * 100)), fill = "gray70") +
  ylab("Percentage of companies") +
  xlab("Price range in dollars (max price - min price)") +
  labs(title = "Price range S&P 500 stocks 2013-2018") +
  theme_bw() +
  theme(panel.border = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  annotate("text", label = "Ford", x = 7.41, y = 7, angle = 90, size = 4) +
  annotate("text", label = "Amazon", x = 1212, y = 4, angle = 90, size = 4) +
  annotate("text", label = "BlackRock", x = 355, y = 5, angle = 90, size = 4) +
  annotate("text", label = "Alphabet (Class A)", x = 805, y = 7, angle = 90, size = 4)
dev.off() 

# IQR ---------------------------------------------------------------------

data %>%
  group_by(company_name) %>%
  mutate(inter_qr = IQR(daily_average, na.rm = T))  %>% 
  select(inter_qr) %>% 
  distinct() %>% 
  filter(company_name == "Alphabet (Class A)")

pdf("iqr.pdf") 
data %>%
  group_by(company_name) %>%
  mutate(inter_qr = IQR(daily_average, na.rm = T))  %>% 
  select(inter_qr) %>% 
  distinct() %>% 
  ggplot() +
  geom_histogram(aes(x = inter_qr, ((..count..)/ length(na.omit(unique(data$company_name))) * 100)), fill = "gray70") +
  ylab("Percentage of companies") +
  xlab("Interquartile range in dollars (upper quartile - lower quartile)") +
  labs(title = "Interquartile range S&P 500 stocks 2013-2018") +
  theme_bw() +
  theme(panel.border = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  annotate("text", label = "Ford", x = 3.38, y = 7, angle = 90, size = 4) +
  annotate("text", label = "Amazon", x = 450, y = 4, angle = 90, size = 4) +
  annotate("text", label = "BlackRock", x = 68.6, y = 6.5, angle = 90, size = 4) +
  annotate("text", label = "Alphabet (Class A)", x = 263, y = 7, angle = 90, size = 4)
dev.off() 

# SD ----------------------------------------------------------------------

data %>%
  group_by(company_name) %>%
  mutate(std_dev = sd(daily_average, na.rm = T))  %>% 
  select(std_dev) %>% 
  distinct() %>% 
  arrange(std_dev) %>% 
  print(n=20)

data %>%
  group_by(company_name) %>%
  mutate(std_dev = sd(daily_average, na.rm = T))  %>% 
  select(std_dev) %>% 
  distinct() %>% 
  arrange(desc(std_dev)) %>% 
  print(n=20)

data %>%
  group_by(company_name) %>%
  mutate(std_dev = sd(daily_average, na.rm = T))  %>% 
  select(std_dev) %>% 
  distinct() %>%
  filter(between(std_dev, 100, 250)) %>% 
  print(n=20)

pdf("sd.pdf") 
data %>%
  group_by(company_name) %>%
  mutate(std_dev = sd(daily_average, na.rm = T))  %>% 
  select(std_dev) %>% 
  distinct() %>% 
  ggplot() +
  geom_histogram(aes(x = std_dev, ((..count..)/ length(na.omit(unique(data$company_name))) * 100)), fill = "gray70") +
  ylab("Percentage of companies") +
  xlab("Standard deviation (average amount price has differed from mean)") +
  labs(title = "Standard deviation S&P 500 stocks 2013-2018") +
  theme_bw() +
  theme(panel.border = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  annotate("text", label = "Ford", x = 1.96, y = 7, angle = 90, size = 4) +
  annotate("text", label = "Amazon", x = 282, y = 4, angle = 90, size = 4) +
  annotate("text", label = "BlackRock", x = 62.3, y = 6.5, angle = 90, size = 4) +
  annotate("text", label = "Alphabet (Class A)", x = 187, y = 7, angle = 90, size = 4) +
  annotate("text", label = "Chipotle Mexican Grill", x = 130, y = 7.5, angle = 90, size = 4)
dev.off() 
# These results are not what I wanted. Looking at the individual graphs, Ford has more volatility than Amazon

# Maximum drawdown --------------------------------------------------------



# Beta --------------------------------------------------------------------


