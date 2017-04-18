#!/usr/bin/env Rscript

## USAGE: calculate_average_coverages.R 
## DESCRIPTION: This script will aggregate average coverages per sample from sns-wes pipeline output

# ~~~~~~~ FUNCTIONS ~~~~~~~ #

get_sampleID_from_filename <- function(filename){
    return(gsub(pattern = '.sample_interval_summary', replacement = '', x = filename))
}

build_all_coverages_df <- function(coverage_files){
    # empty df to hold all the coverages
    all_coverages_df <- data.frame()
    
    # load all the coverages into a single df 
    for(coverage_file in coverage_files){
        message(sprintf("Reading from coverage file: %s", coverage_file))
        
        sample_ID <- get_sampleID_from_filename(basename(coverage_file))
        
        # load the coverage data from the file
        coverage_df <- read.delim(file = coverage_file, header = TRUE, sep = ',')
        rownames(coverage_df) <- coverage_df[["Target"]]
        coverage_df <- coverage_df[5]
        colnames(coverage_df)[1] <- sample_ID
        
        # load the data into the overall df
        if(nrow(all_coverages_df) == 0){
            all_coverages_df <- coverage_df
        } else {
            all_coverages_df <- cbind(all_coverages_df, coverage_df)
        }
    }
    return(all_coverages_df)
}

chrom_regions2df <- function(regions){
    # split the regions into chrom coordinates for BED files
    # regions <- c("chr1:236998847-236998987", "chr1:237001714-237001899")
    regions_df <- as.data.frame(do.call(rbind, strsplit(regions, ':')))
    regions_df <- cbind(regions_df[1],
                        as.data.frame(do.call(rbind, strsplit(as.character(regions_df$V2), '-'))))
    colnames(regions_df) <- c("chrom", "start", "stop")
    return(regions_df)
}

write_BED <- function(df, output_file){
    write.table(x = df, file = output_file, quote = FALSE, sep = '\t', row.names = FALSE, col.names = FALSE)
}
# ~~~~~~~ FILE LOCATIONS ~~~~~~~ #
run_analysis_dir <- "run_analysis_output"
coverages_dir <- file.path(run_analysis_dir, "QC-coverage")

# get the coverage files
coverage_files <- dir(path = coverages_dir, pattern = "interval_summary", full.names = TRUE)


# ~~~~~~~ IMPORT AVERAGE COVERAGE PER REGION PER SAMPLE ~~~~~~~ #
all_coverages_df <- build_all_coverages_df(coverage_files)

avg_file = "average_coverage_per_sample.tsv"
message(sprintf("Writing sample averages to file: %s", avg_file))
write.table(x = all_coverages_df, sep = '\t', quote = FALSE, row.names = TRUE, col.names = NA, 
            file = avg_file)


# ~~~~~~~ CALCULATE AVERAGE OF AVG'S PER REGION ~~~~~~~ #
region_coverages_df <- as.data.frame(rowMeans(all_coverages_df))
colnames(region_coverages_df) <- "average_coverage"

region_avg_file = "average_coverage_per_region.tsv"
message(sprintf("Writing region averages to file: %s", region_avg_file))
write.table(x = region_coverages_df, sep = '\t', quote = FALSE, row.names = TRUE, col.names = FALSE, file = region_avg_file)


# ~~~~~~~ CREATE BED FOR REGIONS WITH LOW COVERAGE ~~~~~~~ #
# coverage < 50
# coverage = 0
low_cutoff <- 50
message(sprintf("Finding regions with coverage below %s", low_cutoff))
low_regions <- region_coverages_df[region_coverages_df["average_coverage"] < low_cutoff, , drop = FALSE]
message(sprintf("Number of regions found: %s", nrow(low_regions)))
low_regions_BED <- chrom_regions2df(rownames(low_regions))
low_BED_file <- sprintf("regions_coverage_below_%s.bed", low_cutoff)
message(sprintf("Writing regions to file: %s", low_BED_file))
write_BED(df = low_regions_BED, output_file = low_BED_file)


message("Finding regions with coverage below 0")
zero_regions <- region_coverages_df[region_coverages_df["average_coverage"] == 0, , drop = FALSE]
message(sprintf("Number of regions found: %s", nrow(zero_regions)))
zero_regions_BED <- chrom_regions2df(rownames(zero_regions))
zero_BED_file <- "regions_with_coverage_0.bed"
message(sprintf("Writing regions to file: %s", zero_BED_file))
write_BED(df = zero_regions_BED, output_file = zero_BED_file)

save.image()

# ~~~~~~ RUN THE ANNOTATION SCRIPT ~~~~~~~ # 
message("Running annotation script on low coverage BED files...")
system(sprintf("Rscript annotate_peaks.R %s %s", 
               low_BED_file, gsub(pattern = ".bed", 
                                  replacement = "_annotation.tsv", 
                                  x = low_BED_file)))
system(sprintf("Rscript annotate_peaks.R %s %s", 
               zero_BED_file, gsub(pattern = ".bed", 
                                   replacement = "_annotation.tsv", 
                                   x = zero_BED_file)))
