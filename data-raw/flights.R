# Run before planes.R and airlines.R
# run 1/31/2018 12:56PM


#setwd("C:/Dropbox/StatAcumen/consult/Rpackages/flightsABQ17")

library(dplyr)
library(readr)

# https://www.transtats.bts.gov/Tables.asp?DB_ID=120&DB_Name=Airline%20On-Time%20Performance%20Data&DB_Short_Name=On-Time
# https://www.transtats.bts.gov/DL_SelectFields.asp

# http://www.transtats.bts.gov/PREZIP/On_Time_On_Time_Performance_2017_1.zip


# 1/31/2018 click on "pre-zipped file", download each one manually
#   (the /Download/ directory no longer exists)

flight_url <- function(year = 2017, month) {
  #base_url <- "http://www.transtats.bts.gov/Download/"
  #sprintf(paste0(base_url, "On_Time_On_Time_Performance_%d_%d.zip"), year, month)
  base_url <- "http://www.transtats.bts.gov/PREZIP/"  ## 1/31/2018 updated name
  fn <- sprintf("On_Time_On_Time_Performance_%d_%d.zip", year, month)
  url <- paste0(base_url, fn)
}

download_month <- function(year = 2017, month) {
  # url <- flight_url(year, month)

  base_url <- "http://www.transtats.bts.gov/PREZIP/"  ## 1/31/2018 updated name
  fn <- sprintf("On_Time_On_Time_Performance_%d_%d.zip", year, month)
  url <- paste0(base_url, fn)


  # temp <- tempfile(fileext = ".zip")
  # download.file(url, temp)
   download.file(url, paste0("data-raw/flights/", fn))

  # files <- unzip(temp, list = TRUE)
  # # Only extract biggest file
  # csv <- files$Name[order(files$Length, decreasing = TRUE)[1]]
  #
  # unzip(temp, exdir = "data-raw/flights", junkpaths = TRUE, files = csv)
  #
  # src <- paste0("data-raw/flights/", csv)
  # dst <- paste0("data-raw/flights/", year, "-", month, ".csv")
  # file.rename(src, dst)
}

# unzip_rename_month <- function(year = 2017, month) {
#   fn <- sprintf("On_Time_On_Time_Performance_%d_%d.zip", year, month)
#
#   files <- unzip(paste0("data-raw/flights/", fn), list = TRUE)
#
#   # Only extract biggest file
#   csv <- files$Name[order(files$Length, decreasing = TRUE)[1]]
#
#   unzip(paste0("data-raw/flights/", fn), exdir = "data-raw/flights", junkpaths = TRUE, files = csv)
#
#   src <- paste0("data-raw/flights/", csv)
#   dst <- paste0("data-raw/flights/", year, "-", month, ".csv")
#   file.rename(src, dst)
# }

# years = 2008:2017
months <- 1:12
needed <- paste0("2008-", months, ".csv")
missing <- months[!(needed %in% dir("data-raw/flights"))]

lapply(missing, download_month, year = 2008)

# for (i_year in years) {
#   for (i_month in months) {
#     unzip_rename_month(i_year, i_month)
#   }
# }

# extracts csv from zip, process, and save
get_abq <- function(path) {
  col_types <- cols(
    DepTime = col_integer(),
    ArrTime = col_integer(),
    CRSDepTime = col_integer(),
    CRSArrTime = col_integer(),
    Carrier = col_character(),
    UniqueCarrier = col_character()
  )
  read_csv(path, col_types = col_types) %>%
    select(
      year = Year, month = Month, day = DayofMonth,
      dep_time = DepTime, sched_dep_time = CRSDepTime, dep_delay = DepDelay,
      arr_time = ArrTime, sched_arr_time = CRSArrTime, arr_delay = ArrDelay,
      carrier = Carrier,  flight = FlightNum, tailnum = TailNum,
      origin = Origin, dest = Dest,
      air_time = AirTime, distance = Distance
    ) %>%
    filter(origin %in% c("ABQ")) %>% # c("JFK", "LGA", "EWR")) %>%
    mutate(
      hour = sched_dep_time %/% 100,
      minute = sched_dep_time %% 100,
      time_hour = lubridate::make_datetime(year, month, day, hour, 0, 0)
    ) %>%
    arrange(year, month, day, dep_time)
}

all <- lapply(dir("data-raw/flights", full.names = TRUE), get_abq)  ## From zip files
flights <- bind_rows(all)
flights$tailnum[flights$tailnum == ""] <- NA

save(flights, file = "data/flights.rda", compress = "bzip2")
