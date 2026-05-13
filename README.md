
# ch.fso.hesta

The ch.fso.hesta package provides versioned time series data
and their meta information for scientific research.
In addition, the package contains the
extract-transform-load (ETL) functionality that
sources the data from its original provider.

## Browse Time Series Data

You can use GitHub's ability to render to csv to explore the datasets

## Basic Data Consumption via opentimeseries


```r
remotes::install_github("opentsi/opentimeseries")
library(opentimeseries)

# first param `series` defaults to NULL
# fetches all series from `remove_archive``
ts <- read_open_ts(
  remote_archive = "opentsi/ch.fso.hesta" 
)

ts
```

