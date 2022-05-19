# Data cleaning
# Emilio Lehoucq

# Loading libraries -------------------------------------------------------

library(tidyverse)

# Functions ---------------------------------------------------------------

missing_data <- function(dataset){
  
  cbind(
    lapply(
      lapply(dataset, is.na)
      , sum)
  )
  
}

# Reading data ------------------------------------------------------------

sp <- read_csv("Data/s&p_individual/all_stocks_5yr.csv")

spn <- read_csv("Data/s&p_individual_names/data/constituents.csv")

# Exploring datasets ------------------------------------------------------

dim(sp) # p = 7, n = 619040
head(sp)

dim(spn) # p = 3, n = 505
head(spn)

# Cleaning names ----------------------------------------------------------

names(sp) <- tolower(names(sp))

names(spn) <- tolower(names(spn))

# Cleaning format ---------------------------------------------------------

str(sp) # date date, name character, all others double

str(spn) # all character

# Checking missing data ---------------------------------------------------

missing_data(sp) # 11 NAs on open, 8 on high, 8 on low. Not worrisome given n

missing_data(spn) # none

# Exploring overlap between the datasets ----------------------------------

min(sp$date) # 2013-2-8
max(sp$date) # 2018-2-7
# it's unclear the data where the list of companies in spn was made

table(sp$name[!sp$name %in% spn$symbol])
length(table(sp$name[!sp$name %in% spn$symbol])) # 87 companies
# could be companies that have been in and out of the index, companies that changed their ticker
table(sp$name[!sp$name %in% spn$symbol]) # those 87 companies will create 105,115 missing values
length(table(sp$name[sp$name %in% spn$symbol])) # still have 418 companies, or ~84% of 500

# Merging data ------------------------------------------------------------

sp500 <- left_join(sp, spn, by = c("name" = "symbol"))

# Exploring merged data ---------------------------------------------------

missing_data(sp500) # indeed, 105,115 missing values

head(sp500)

# Rename columns in merged data -------------------------------------------

colnames(sp500)[7] <- "ticker"
colnames(sp500)[8] <- "company_name"

# Save data ---------------------------------------------------------------

saveRDS(sp500, file = "Data/sp500.rds")
