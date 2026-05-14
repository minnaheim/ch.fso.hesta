library(deloRean)
library(opentimeseries)

## Example Step 1, fetch vintages

library(tsdbapi)
# check if dataset exists
keys <- read_dataset_keys("ch.fso.hesta")
length(keys)


fetch_vintages_batched <- function(keys, batch_size = 50) {
  batches <- split(keys, ceiling(seq_along(keys) / batch_size))
  results <- vector("list", length(batches))

  for (i in seq_along(batches)) {
    cat(sprintf("Fetching batch %d/%d (%d keys)...\n", i, length(batches), length(batches[[i]])))
    results[[i]] <- read_ts_history(batches[[i]])
    cat(sprintf("  Done batch %d/%d\n", i, length(batches)))
  }

  do.call(c, results)
}

all_vintages <- fetch_vintages_batched(keys, batch_size = 50)
head(all_vintages, n =20)



## Example Step 2, Generate History
# read_ts_history returns names as key_YYYYMMDD; convert to key.YYYY-MM
# so that create_vintage_dt can strip the .YYYY-MM suffix to recover the key
vintage_date_str <- sub(".+_([0-9]{8})$", "\\1", names(all_vintages))
vintage_dates <- as.Date(vintage_date_str, format = "%Y%m%d")

names(all_vintages) <- sub("_([0-9]{4})([0-9]{2})[0-9]{2}$", ".\\1-\\2", names(all_vintages))
# remove the dataset prefix so keys match the relative key structure in the archive
names(all_vintages) <- sub("^ch\\.fso\\.hesta\\.", "", names(all_vintages))
class(all_vintages) <- c(class(all_vintages), "tslist")


## Step 3: Create vintages data.table
create_vintage_dt_batched <- function(vintage_dates, all_vintages, batch_size = 200) {
  n <- length(vintage_dates)
  batches <- split(seq_len(n), ceiling(seq_len(n) / batch_size))
  results <- vector("list", length(batches))

  for (i in seq_along(batches)) {
    idx <- batches[[i]]
    cat(sprintf("Creating vintage dt batch %d/%d (%d series)...\n", i, length(batches), length(idx)))
    results[[i]] <- create_vintage_dt(vintage_dates[idx], all_vintages[idx])
    cat(sprintf("  Done batch %d/%d\n", i, length(batches)))
  }

  data.table::rbindlist(results)
}

vintages_dt <- create_vintage_dt_batched(vintage_dates, all_vintages, batch_size = 200)
head(vintages_dt, n = 100)
# vintages_dt[1]$data

saveRDS(vintages_dt, "inst/vintages_dt.rds")
# vintages_dt <- readRDS("inst/vintages_dt.rds")  # reload if needed

archive_import_history(vintages_dt, repository_path = ".")


## Step 5: Write & Validate Metadata

# check if info is available via api
indpau_meta <- read_dataset_ts_metadata("ch.fso.hesta") # empty list

render_metadata()
meta <- read_meta(".")
validate_metadata(meta) # TRUE


## Step 6: Seal Archive
key <- "679fb20c843b2ae04d8e5d1e1494d3216dbe947d5a783ab3063f6351ccb642da"
devtools::load_all()
library(deloRean)
library(opentimeseries)
library(digest)
checksum_input <- generate_checksum_input(key = key)
archive_seal(checksum_input)


## Step 7: Final Checks & Automation
devtools::load_all()
handle_update(key = key)

library(devtools)
check()
install()


