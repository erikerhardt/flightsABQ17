# Run after flights.R
# run 1/31/2018 12:56PM

library(dplyr)
library(readr)

# Update URL from
# http://www.faa.gov/licenses_certificates/aircraft_certification/aircraft_registry/releasable_aircraft_download/
#src <- "http://registry.faa.gov/database/AR062014.zip"
#src <- "http://registry.faa.gov/database/yearly/ReleasableAircraft.2017.zip"
fn <- "ReleasableAircraft.zip"
src <- paste0("http://registry.faa.gov/database/", fn) # all
lcl <- "data-raw/planes"

if (!file.exists(lcl)) {
  # tmp <- tempfile(fileext = ".zip")
  download.file(src, paste0(lcl, "/", fn))

  dir.create(lcl)
  unzip(paste0(lcl, "/", fn), exdir = lcl, junkpaths = TRUE)
}

## Remove initial 3 unicode characters from MASTER.txt and ACFTREF.txt

master <- read.csv("data-raw/planes/MASTER.txt", stringsAsFactors = FALSE, strip.white = TRUE)
names(master) <- tolower(names(master))

keep <- master %>%
  tbl_df() %>%
  select(nnum = n.number, code = mfr.mdl.code, year = year.mfr)

ref <- read.csv("data-raw/planes/ACFTREF.txt", stringsAsFactors = FALSE,
  strip.white = TRUE)
names(ref) <- tolower(names(ref))

ref <- ref %>%
  tbl_df() %>%
  select(code, mfr, model, type.acft, type.eng, no.eng, no.seats, speed)

# Combine together

all <- keep %>%
  inner_join(ref) %>%
  select(-code)
all$speed[all$speed == 0] <- NA
all$no.eng[all$no.eng == 0] <- NA
all$no.seats[all$no.seats == 0] <- NA

engine <- c("None", "Reciprocating", "Turbo-prop", "Turbo-shaft", "Turbo-jet",
  "Turbo-fan", "Ramjet", "2 Cycle", "4 Cycle", "Unknown", "Electric", "Rotary")
all$engine <- engine[all$type.eng + 1]
all$type.eng <- NULL

acft <- c("Glider", "Balloon", "Blimp/Dirigible", "Fixed wing single engine",
  "Fixed wing multi engine", "Rotorcraft", "Weight-shift-control",
  "Powered Parachute", "Gyroplane")
all$type <- acft[all$type.acft]
all$type.acft <- NULL

all$tailnum <- paste0("N", all$nnum)

load("data/flights.rda")

planes <- all %>%
  select(
    tailnum, year, type, manufacturer = mfr, model = model,
    engines = no.eng, seats = no.seats, speed, engine
  ) %>%
  semi_join(flights, "tailnum") %>%
  arrange(tailnum)

write_csv(planes, "data-raw/planes.csv")
save(planes, file = "data/planes.rda")
