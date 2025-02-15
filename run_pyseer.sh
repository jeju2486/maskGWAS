#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 -t <tree_file> -p <phenotype_file> -i <unitig_output_dir> -o <output_dir> -P <prefix> -T <threads> -s <pyseer_scripts_dir>"
    exit 1
}

# Parse command-line arguments
while getopts ":t:p:i:o:P:T:s:" opt; do
  case $opt in
    t) treefile="$OPTARG"
    ;;
    p) phenotype="$OPTARG"
    ;;
    i) unitig_result="$OPTARG"
    ;;
    o) result_dir="$OPTARG"
    ;;
    P) prefix="$OPTARG"
    ;;
    T) threads="$OPTARG"
    ;;
    s) pyseer_scripts_dir="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        usage
    ;;
  esac
done

# Check that all required arguments are provided
if [ -z "$treefile" ] || [ -z "$phenotype" ] || [ -z "$unitig_result" ] || [ -z "$result_dir" ] || [ -z "$prefix" ] || [ -z "$threads" ] || [ -z "$pyseer_scripts_dir" ]; then
    usage
fi

# Create output directory if it doesn't exist
mkdir -p "$result_dir"

# Check if the Pyseer output file already exists
if [ ! -f "$result_dir/${prefix}_kmers.txt" ]; then
    # Run phylogeny distance calculation
    python "$pyseer_scripts_dir"/phylogeny_distance.py --lmm "$treefile" > "$result_dir"/"${prefix}_phylogeny.tsv"
    
    # Run pyseer if the output file does not exist
    pyseer --lmm --phenotypes "$phenotype" --kmers "$unitig_result"/survived_unitigs.pyseer.gz --similarity "$result_dir"/"${prefix}_phylogeny.tsv" --min-af 0.03 --output-patterns "$result_dir"/kmer_patterns.txt --cpu "$threads" > "$result_dir"/"${prefix}_kmers.txt"
else
    echo "Pyseer output file ${prefix}_kmers.txt already exists. Skipping Pyseer analysis."
fi

# Run count_patterns.py and capture the outputrm scc
threshold_output=$(python "$pyseer_scripts_dir"/count_patterns.py "$result_dir"/kmer_patterns.txt)

# Extract the threshold from the output (assuming it's in the format "Threshold: 8.13E-08")
threshold=$(echo "$threshold_output" | grep "Threshold" | awk '{print $2}')

echo "Threshold is $threshold"

# Filter significant k-mers based on the threshold
cat <(head -1 "$result_dir"/"${prefix}_kmers.txt") <(awk -v threshold="$threshold" '$4 < threshold {print $0}' "$result_dir"/"${prefix}_kmers.txt") > "$result_dir"/significant_kmers.txt

# Filter outliers
python filter.outlier.py -i "$result_dir/significant_kmers.txt" -o "$result_dir"

# Remove outliers from the k-mers file
awk 'NR==FNR {a[$1]; next} FNR==1 || !($1 in a)' "$result_dir"/high_outliers_kmers.txt "$result_dir"/"${prefix}_kmers.txt" > "$result_dir"/"${prefix}_kmers.filtered.txt"

# Output message to confirm completion
echo "Filtered k-mers saved to "$result_dir"/${prefix}_kmers.filtered.txt"
