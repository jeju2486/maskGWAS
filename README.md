# maskGWAS

**maskGWAS** is an add-on tool of [unitig-caller](https://github.com/bacpop/unitig-caller) and [pyseer](https://github.com/weecology/pyseer) designed to detect genomic co-variation. This works by masking target genes within unitigs before performing k-mer based GWAS to identify significant variation associated with target gene carriage. 

**Notes:**
- All the codes at pyseer_codes folder are adapted from [pyseer](https://github.com/weecology/pyseer). Here I copied it just for easier running. 

## Requirements

Before using `maskGWAS`, ensure the following software are installed:

1. **[minimap2](https://github.com/lh3/minimap2)** (version 2.24 or higher)
2. **[BEDtools](https://bedtools.readthedocs.io/en/latest/)** (version 2.30.0 or higher)
3. **[PLINK 1.9](https://www.cog-genomics.org/plink/1.9/)** (Note: PLINK 2 is **not** supported)
4. **[unitig-caller](https://github.com/bacpop/unitig-caller)** (or higher)
5. **[BWA](http://bio-bwa.sourceforge.net/)** (version 0.7.17 or higher)
6. **[pyseer](https://github.com/weecology/pyseer)** (version 1.3.11 or higher)
7. **[ABRicate](https://github.com/tseemann/abricate)** (version 1.0.0 or higher)

## Installation

Clone the repository to your local directory:

```ruby
git clone https://github.com/jeju2486/maskGWAS.git
cd maskGWAS
```
## Input

To run this analysis pipeline you will need:
- assembly files in FASTA format OR an alignment file.
- target sequence(s) to mask in FASTA format OR start and end coordinates for target region in tab-delimited format.
- annotation files in GFF format.

## Usage

### 1. Calculate Linkage Disequilibrium (LD)

#### a. Using FASTA Files

To calculate LD using fasta files in your directory, run:

```ruby
bash run_ld_calculation.sh -i "$input_dir" -o "$output_dir" -t "number_of_cpus"
```

#### b. Using Core Alignment Files (Optional)

If you have a core alignment file from [PIRATE](https://github.com/SionBayliss/PIRATE) or similar tools, you can reduce variant calling time by running the following script:

```ruby
bash run_ld_calculation_from_aln.sh -i "$pirate_result_dir" -o "$output_dir" -t "number_of_cpus"
```

### 2. Visualize LD Decay (Optional)

Visualize LD decay using `ggplot2` in R:

```ruby
Rscript plotting_lddecay.r -i "$output_dir/ld_results_sampled.ld" -o "$output_dir"
```
**Notes:**
- Ensure the first file in the directory is your reference genome.

### 3. Mask Target Gene

Run the masking script to generate SAM/BED files and LD information.

#### a. Using FASTA File

```ruby
bash run_maskfasta.sh \
  -g "/path/to/target_sequence.fasta" \
  -i "/path/to/input_dir" \
  -d "LD_threshold_value" \
  -o "/path/to/output_dir" \
  -t "number_of_cpus" \
  -x   #Optional debugging mode (Warning: output files will get messy)
```

#### b. Using Region Coordinates

If you know the start and end coordinates of the specific regions you want to mask, you can use the `-s` parameter to specify this. The file should be in tab-delimited format and specify the contig and start and end points:

`target region.tsv`

```
Reference	Gene_presence	Contig	Start	End
GCF_000144955.fas	Yes	NC_017338.2	33707	57871
GCF_000159535.fas	Yes	NC_017342.1	459032	486212
GCF_000189455.fas	No	NZ_CP025395.1	33931	34407
GCF_000568455.fas	Yes	NZ_CP007176.1	34275	88793
```

Usage would be as follows:

```ruby
bash run_maskfasta.sh\
  -s "path/to/target_region.tsv" \
  -i "/path/to/input_dir" \
  -d "LD_threshold_value" \
  -o "/path/to/output_dir" \
  -t "number_of_cpus"
```

## Output

- **`./sam/`**  
  Contains sequence Alignment/Map (SAM) files.
- **`./bed/`**  
  Contains BED files (simplified SAM files).
- **`./ld_ref/`**  
  Contains LD information files, including BED and FASTA files for LD regions.
- **`./unitig_output/`**  
  1) `unitig.output.pyseer`: Unitigs of whole genomes used for analysis.
  2) `potential.kmer_output.txt`: k-mers from LD regions.
  3) `extracted.unitig.out.pyseer`: Unitig files without LD regions, formatted for pyseer.

## 4. Running pyseer

`maskGWAS` automates running `pyseer`.

```ruby
bash run_pyseer.sh \
  -t "$treefile" \
  -p "$phenotype" \
  -i "$maskfasta_output_dir/unitig_output" \
  -o "$pyseer_output_dir" \
  -P "prefix" \          # Optional
  -T "number_of_cpus" \  # Optional
  -s "$pyseer_script"
```

## 5. Plotting pyseer results (Optional)

Generate plots for `pyseer` results. Ensure directory paths are correctly set.

```ruby
bash run_pyseer_plotting.sh \
  -r "$input_fasta_dir" \
  -g "$gff_dir" \
  -s "$pyseer_script" \
  -o "$pyseer_output_dir" \
  -p "prefix"  # Optional: Prefix for output files
```
This code will automatically find gff files in `$gff_dir` corresponding to the fasta files in `$input_fasta_dir` and assume all of them are reference genome but not the sample one (Read the [pyseer tutorial page](https://pyseer.readthedocs.io/en/master/tutorial.html#k-mer-association-with-mixed-effects-model) for more detail)

To make the annotation plot use the plotting_annotation.R file (Original code from [pyseer tutorial page](https://pyseer.readthedocs.io/en/master/tutorial.html#k-mer-association-with-mixed-effects-model))

```ruby
Rscript plotting_annotation.R "$pyseer_output_dir"/gene_hits_saureus.txt annotation pdf,svg
```

**Notes:**
- The prefix should ideally match the one used in `run_pyseer.sh`.

## Contact

For questions, issues, or contributions, please open an issue on the [GitHub repository](https://github.com/jeju2486/maskGWAS) or contact the maintainer.
