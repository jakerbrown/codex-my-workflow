#!/usr/bin/env Rscript

script_file_arg <- commandArgs(trailingOnly = FALSE)
script_file_arg <- script_file_arg[grepl("^--file=", script_file_arg)]
script_dir <- dirname(normalizePath(sub("^--file=", "", script_file_arg[[1]])))
setwd(script_dir)

system2("Rscript", "fetch_transcripts.R")
system2("Rscript", "analyze_cached.R")
