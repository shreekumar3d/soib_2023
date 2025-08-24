library(tidyverse)
library(lme4)
library(VGAM)
library(parallel)

# preparing data for specific mask (this is the only part that changes, but automatically)
cur_metadata <- get_metadata(cur_mask)
speclist_path <- cur_metadata$SPECLISTDATA.PATH
databins_path <- cur_metadata$DATA.PATH # for databins

get_free_ram <- function() {
#               total        used        free      shared  buff/cache   available
#Mem:        65572748     1544972    62672624        2976     1995520    64027776
#Swap:        8388604           0     8388604
#"available" is how much more RAM we can be use without swapping
  ram <- system("free | awk '/Mem:/ {print $7}'", intern = TRUE)
  ram <- as.integer(ram)*1024
  return(ram)
}

# don't run if no species selected
message(paste("Loading",speclist_path))
load(speclist_path)
to_run <- (1 %in% specieslist$ht) | (1 %in% specieslist$rt) |
  (1 %in% restrictedspecieslist$ht) | (1 %in% restrictedspecieslist$rt)


# singleyear = interannualupdate
singleyear = FALSE
# not using single year modelling approach, since test runs showed that
# single year models produce notably higher estimates than full-year models


if (to_run == TRUE) {

  
  # for the full country analysis, runs are split among multiple systems, and use
  # separate subsampled datasets. We need to ensure this information exists.
  # else, all 1000 runs are on one system.
  if (cur_mask == "none") {
    
    if (!exists("my_assignment")) {
      return("'my_assignment' is empty! Please specify IDs of data files assigned to you.")
    }
    
    cur_assignment <- my_assignment
    
  } else {
    
    if (!exists("my_assignment")) {
      cur_assignment <- 1:1000
    } else {
      cur_assignment <- my_assignment
    }
    
  }
  
  ###

  source('00_scripts/00_functions.R')
  
  message(paste("Loading:",speclist_path))
  load(speclist_path)
  databins_path_metadata <- paste0(databins_path,'-metadata')
  message(paste("Loading:",databins_path_metadata))
  load(paste(databins_path_metadata))
  
  lsa = specieslist %>% filter(!is.na(ht) | !is.na(rt))
  listofspecies = c(lsa$COMMON.NAME, restrictedspecieslist$COMMON.NAME)
  speclen = length(listofspecies)
  
  # creating new directory if it doesn't already exist
  if (!dir.exists(cur_metadata$TRENDS.PATHONLY)) {
    dir.create(cur_metadata$TRENDS.PATHONLY, 
               recursive = T)
  }

  trends_stats_dir <- "output/stats"
  # creating new directory if it doesn't already exist
  if (!dir.exists(trends_stats_dir)) {
    dir.create(trends_stats_dir,
               recursive = T)
  }
  
  for (k in cur_assignment)
  {
    
    # file names for individual files
    write_path <- cur_metadata %>% 
      dplyr::summarise(TRENDS.PATH = glue("output/trends_{k}.csv")) %>% 
      as.character()

    data_path = cur_metadata %>% 
      dplyr::summarise(SIMDATA.PATH = glue("{SIMDATA.PATHONLY}data{k}.RData_opt")) %>%
      as.character()
    
    
    tictoc::tic(glue("Species trends for {cur_mask}: {k}/{max(cur_assignment)}"))
    
    # read data files
    message(paste("Loading", data_path))
    load(data_path)
    load("00_data/species_names.RData")
    load("00_data/timegroups.RData")
    run_stats_path <- paste0(dirname(databins_path),'/species_run_stats.RData')
    message(paste("Loading", run_stats_path))
    load(run_stats_path)

    # map timegroups to strings
    data_filt$timegroups <- timegroups_names$timegroups[data_filt$timegroups]

    cols_temp <- if (singleyear == FALSE) {
      c("gridg1", "gridg2", "gridg3", "gridg4", "month", "timegroups")
    } else if (singleyear == TRUE) {
      c("gridg1", "gridg2", "gridg3", "gridg4", "month")
    }

    data <- data_filt %>% 
      mutate(across(.cols = all_of(cols_temp), ~ as.factor(.))) %>% 
      mutate(gridg = gridg3)

    rm(cols_temp)
    
    # start parallel
    n.cores = worker_procs # From command line

    species_todo <- length(species_to_process)
    if (species_todo==0) {
      species_todo <- length(listofspecies)
    } else {
      species_run_stats <- species_run_stats %>%
	                   filter(species_name %in% species_to_process)
    }
    message(paste0("Processing Species:", species_todo))

    next_species <- 1
    species_threads <- min(n.cores, species_todo) # if very few species then can't engage all cores
    species_threads_active <- 0
    species_done <- 0
    trends0 <- NULL
    
    # species_run_stats is ordered in descending order of runtime.
    # longest running species typically consume max memory as well
    # so peak memory consumption should happen in the beginning
    # then this will taper.  Doing this also ensures that the job
    # will fail in the beginning rather than later due to OOM
    # scenarios.
    #
    # the table has species name, time to run, and peakRAM usage
    # for that run.  Having all this as data makes it possible to
    # "schedule" intelligently later

    free_ram <- get_free_ram() - ram_safety_margin*1000*1024

    # Minimum we can run is 1 species at a time. If we don't have memory
    # for that, better to exit now!
    min_ram_needed <- max(species_run_stats$peakRAM)*1000*1024

    if (min_ram_needed > free_ram) {
      message("Not enough RAM to fit even single species.")
      message(paste("Min reqd:", min_ram_needed, "Available:", free_ram))
      message("Increase container memory limits and try again.")
      quit()
    }

    if(ram_interleave) {
      message("Running jobs with runtime length, combined with RAM interleave scheduling")
      # bucket based on RAM. Mix of jobs with different RAM (3+2+1)=6 = 2x3 cores
      # or 2 GB ram per core
      bucket1 <- subset(species_run_stats, peakRAM < 1000)
      bucket2 <- subset(species_run_stats, peakRAM >= 1000 & peakRAM < 2000)
      bucket3 <- subset(species_run_stats, peakRAM >= 2000)

      # clear
      species_run_stats <- species_run_stats[0, ]
      # combine buckets with interleaving
      iters <- max(nrow(bucket1),nrow(bucket2),nrow(bucket3))
      for (i in 1:iters) {
        if(i<=nrow(bucket3)) {
          species_run_stats[nrow(species_run_stats)+1,] <- bucket3[i,]
        }
        if(i<=nrow(bucket2)) {
          species_run_stats[nrow(species_run_stats)+1,] <- bucket2[i,]
        }
        if(i<=nrow(bucket1)) {
          species_run_stats[nrow(species_run_stats)+1,] <- bucket1[i,]
        }
      }
    } else {
      message("Running jobs with runtime length scheduling")
    }

    message("Free RAM at start ", as.integer(free_ram/1000000), " MB")
    try_thread_start <- TRUE
    repeat {
      # start as many threads as we have (remaining) capacity for
      started <- 0
      if(try_thread_start) {
        while((next_species<=species_todo) && (species_threads_active < species_threads)) {
	  min_ram_needed <- species_run_stats$peakRAM[next_species]*1000*1024
          if(min_ram_needed > free_ram) {
	      message("Won't start ", species_threads-species_threads_active,
	              " threads due to insufficient RAM (needed for 1 more: ",
	              as.integer(min_ram_needed/1000000), " MB free:",
		      as.integer(free_ram/1000000), " MB)")
	      break
	  }

	  #this_species = listofspecies[next_species]
	  this_species <- species_run_stats$species_name[next_species]
	  species_index <- which(species_names$COMMON.NAME==this_species)

	  message("Starting: ",
                  this_species, ", estimated peakRAM: ",
                  as.integer(min_ram_needed/1000000), " MB,",
                  " runtime: ", species_run_stats$time[next_species], " seconds")

	  # assume job will consume this much
	  free_ram <- free_ram - min_ram_needed

	  mcparallel(singlespeciesrun(stats_dir = trends_stats_dir,
		       data = data,
		       species_index = species_index,
                       species = this_species,
                       specieslist = specieslist, 
                       restrictedspecieslist = restrictedspecieslist,
                       singleyear = singleyear))
          next_species <- next_species + 1
	  species_threads_active <- species_threads_active + 1
          started <- started + 1
        }
      }

      if(started > 0) {
        message(paste("Threads started:", started))
      }

      message("T=",proc.time()[3],
		  " Estmated Peak Free RAM:", as.integer(free_ram/1000000), " MB",
		  " Threads:", species_threads_active,
		  " Done:", species_done,
		  " Pending:", species_todo+1-next_species)

      done <- 0
      result_set <- mccollect(timeout = 10, wait=FALSE)
      if (!is.null(result_set)) {
        for (result in result_set) {
	  # first result is the species name, so
	  done_index <- which(species_run_stats$species_name==result[1])
	  done_mem <- species_run_stats$peakRAM[done_index]*1000*1024
	  free_ram <- free_ram + done_mem
          trends0 <- cbind(trends0, result)
	  species_threads_active <- species_threads_active - 1
	  species_done <- species_done + 1
          done <- done + 1
        }
        try_thread_start <- TRUE
      } else {
        try_thread_start <- FALSE
      }

      if (done > 0) {
        message(paste("Threads finished:", done))
      }

      if((next_species>species_todo) && (species_threads_active == 0)) {
        break
      }
    }

    trends = data.frame(trends0) %>% 
      # converting first row of species names (always true) to column names
      magrittr::set_colnames(.[1,]) %>% 
      slice(-1) %>% 
      {if (singleyear == FALSE) {
        
        mutate(.,
                timegroupsf = rep(databins$timegroups, 2),
                timegroups = rep(databins$year, 2),
                type = rep(c("freq", "se"), 
                            # will always have 2*N.YEAR rows (freq, se)
                            each = length(soib_year_info("timegroup_lab"))),
                sl = k) %>%  # sim number
        # pivoting species names longer
        pivot_longer(-c(timegroups, timegroupsf, sl, type), 
                      values_to = "value", names_to = "COMMON.NAME") %>% 
        pivot_wider(names_from = type, values_from = value) %>% 
        # numerical ID for species names, for arranging
        mutate(sp = row_number(), .by = timegroupsf) %>%
        arrange(sl, sp) %>%
        dplyr::select(-sp) %>% 
        # reordering
        relocate(sl, COMMON.NAME, timegroupsf, timegroups, freq, se)
            
      } else if (singleyear == TRUE) {

        mutate(.,
                type = rep(c("freq", "se"), 
                            each = 1),
                sl = k) %>%  # sim number
        # pivoting species names longer
        pivot_longer(-c(sl, type), 
                      values_to = "value", names_to = "COMMON.NAME") %>% 
        pivot_wider(names_from = type, values_from = value) %>% 
        # numerical ID for species names, for arranging
        mutate(sp = row_number()) %>%
        arrange(sl, sp) %>%
        dplyr::select(-sp) %>% 
        # reordering
        relocate(sl, COMMON.NAME, freq, se) |> 
        # bringing back timegroups columns
        mutate(timegroups = soib_year_info("latest_year"),
               timegroupsf = as.character(soib_year_info("latest_year")))

      }} %>% 
      # make sure freq and se are numerical
      mutate(across(c("freq", "se"), ~ as.numeric(.)))
    
    
    # if full run, overwrite the CSV
    # else append single year results to all previous year results
    if (singleyear == FALSE) {

      write.csv(trends, file = write_path, row.names = FALSE)

    } else if (singleyear == TRUE) {

      trends_old <- read.csv(write_path, header = TRUE) |> 
        filter(timegroups != soib_year_info("latest_year"))

      trends_new <- trends_old |> 
        bind_rows(trends) |> 
        left_join(specieslist |> 
                    mutate(order = row_number(),
                            ht = NULL,
                            rt = NULL), 
                  by = "COMMON.NAME") |> 
        arrange(sl, order, timegroups) |> 
        dplyr::select(-order)

      write.csv(trends_new, file = write_path, row.names = FALSE)

    }

    
    tictoc::toc() 
    
    # maybe unnecessary time-consuming step:
    # worth trying the profiling mentioned here http://adv-r.had.co.nz/memory.html
    # https://stackoverflow.com/questions/1467201/forcing-garbage-collection-to-run-in-r-with-the-gc-command
    # gc()
    
    }
  
} else {
  
  print(glue("Skipping running species trends for {cur_mask}"))
  
}
