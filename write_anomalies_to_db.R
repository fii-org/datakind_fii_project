# Import output of anomaly detection python script (CSV) into Postgres table * with timestamp 

library(dplyr)
require(RPostgreSQL)


# User-entered variables
ANOMALY_PATH <- "/Users/shannonlauricella/Documents/datakind/anomalous.csv"
date_in_algo <- '2017-04-01'
measure_in_algo <- 'TotalIncome'

# Database info
db <- "fii_data"
hostname = "localhost"
port_no = 5432
username = 'shannonlauricella'
password = pw
drv <- dbDriver("PostgreSQL")

# Input Data --------------------------------------------------------------
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = db,
                 host = hostname, port = port_no,
                 user = username, password = pw)
rm(pw) # removes the password


anomaly_output <- read.csv(ANOMALY_PATH, header=T) %>%
  rename(Value = TotalIncome) %>%
  mutate(JournalDate = as.Date(date_in_algo), Measure = measure_in_algo, Status = 'FLAGGED', AuthorID = "System generated", InsertDate = Sys.time())

dbWriteTable(con, "fii_anomalies", 
             value = anomaly_output, append=TRUE, row.names = FALSE)




