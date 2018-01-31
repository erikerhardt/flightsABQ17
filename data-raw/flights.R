# Run before planes.R and airlines.R
# run 1/31/2018 2:30AM

library(dplyr)
library(readr)

# https://www.transtats.bts.gov/Tables.asp?DB_ID=120&DB_Name=Airline%20On-Time%20Performance%20Data&DB_Short_Name=On-Time
# https://www.transtats.bts.gov/DL_SelectFields.asp

# 1/31/2018 click on "pre-zipped file", download each one manually
#   (the /Download/ directory no longer exists)

# flight_url <- function(year = 2017, month) {
#   base_url <- "http://www.transtats.bts.gov/Download/"
#   sprintf(paste0(base_url, "On_Time_On_Time_Performance_%d_%d.zip"), year, month)
# }
#
# download_month <- function(year = 2017, month) {
#   url <- flight_url(year, month)
#
#   temp <- tempfile(fileext = ".zip")
#   download.file(url, temp)
#
#   files <- unzip(temp, list = TRUE)
#   # Only extract biggest file
#   csv <- files$Name[order(files$Length, decreasing = TRUE)[1]]
#
#   unzip(temp, exdir = "data-raw/flights", junkpaths = TRUE, files = csv)
#
#   src <- paste0("data-raw/flights/", csv)
#   dst <- paste0("data-raw/flights/", year, "-", month, ".csv")
#   file.rename(src, dst)
# }

#unused# unzip_month <- function(year = 2017, month) {
#unused#   #url <- flight_url(year, month)
#unused#   #
#unused#   #temp <- tempfile(fileext = ".zip")
#unused#   #download.file(url, temp)
#unused#
#unused#   temp <- sprintf(paste0("data-raw/flights/", "On_Time_On_Time_Performance_%d_%d.zip"), year, month)
#unused#
#unused#
#unused#   files <- unzip(temp, list = TRUE)
#unused#   # Only extract biggest file
#unused#   csv <- files$Name[order(files$Length, decreasing = TRUE)[1]]
#unused#
#unused#   unzip(temp, exdir = "data-raw/flights", junkpaths = TRUE, files = csv)
#unused#
#unused#   src <- paste0("data-raw/flights/", csv)
#unused#   dst <- paste0("data-raw/flights/", year, "-", month, ".csv")
#unused#   file.rename(src, dst)
#unused# }
#unused#
#unused#
#unused# months <- 1:12
#unused# needed <- paste0("2017-", months, ".csv")
#unused# missing <- months[!(needed %in% dir("data-raw/flights"))]
#unused#
#unused# #lapply(missing, download_month, year = 2017)
#unused# lapply(missing, unzip_month, year = 2017)

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

all <- lapply(dir("data-raw/flights", full.names = TRUE), get_abq)
flights <- bind_rows(all)
flights$tailnum[flights$tailnum == ""] <- NA

save(flights, file = "data/flights.rda", compress = "bzip2")
