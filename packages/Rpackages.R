# To avoid installing the entire tidyverse
install.packages(c(
  "broom",
  "caret",
  "data.table",
  "dplyr",
  "ggthemes",
  "ggplot2",
  "glmnet",
  "janitor",
  "jsonlite",
  "lubridate",
  "purrr",
  "readr",
  "readxl",
  "rmarkdown",
  "stringr",
  "tibble",
  "tidyr",
  "writexl"
))

# More important packages
install.packages(c(
  "curl",
  "ggrepel",
  "ggridges",
  "httpgd",
  "pacman",
  "remotes",
  "renv",
  "styler"
  # "tidymodels",
  # "tidyverse",
))

remotes::install_github("devOpifex/r.nvim")
remotes::install_github("jalvesaq/colorout")
