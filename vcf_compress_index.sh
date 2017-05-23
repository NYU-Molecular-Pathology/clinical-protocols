#!/bin/bash

## USAGE: vcf_compress_index.sh /path/to/file1.vcf /path/to/file2.vcf ...
## DESCRIPTION: This script will compress and index all vcf files supplied

# ~~~~~~~~~~ CUSTOM ENVIRONMENT ~~~~~~~~~~ #
source /ifs/data/molecpathlab/scripts/settings
source /ifs/data/molecpathlab/scripts/bash_settings.sh

tabix_bin="${bin_dir}/htslib-1.3.1/tabix"
bgzip_bin="${bin_dir}/htslib-1.3.1/bgzip"

validate_vcf () {
    local vcf_file="$1"
    case "$vcf_file" in
    *.vcf)
    [ -f "$vcf_file" ] && exit 0 || exit 1
    ;;
    *)
    exit 1
    ;;
esac
}

#~~~~~ PARSE ARGS ~~~~~~#
num_args_should_be "greater_than" "0" "$#"
vcf_files="${@:1}" # accept a space separated list of files starting at the first arg


#~~~~~ RUN ~~~~~~#
for vcf_file in $vcf_files; do
    (
    validate_vcf "$vcf_file"
    ) && {
    print_div ;
    printf "Input file: %s\n\n" "$vcf_file" ;
    file_basename="$(basename "$vcf_file")" ;
    output_zip="$(dirname "$vcf_file")/${file_basename}.gz" ;
    printf "Output compressed file: %s\n\n" "$output_zip" ;
    $bgzip_bin -c "$vcf_file" > "$output_zip" && $tabix_bin -p vcf "$output_zip" ;
    print_div ;
    } || { printf "Skipping %s\n\n" "$vcf_file"; }
done
