# avian-flu-whole-genome
avian flu whole genome Nextstrain build

## Build Overview
- **Build Name**: Pacific Flyway Avian Influenza Whole Genome Build
- **Pathogen/Strain**: Influenza A H5N1
- **Scope**: Pacific Flyway (BC, WA, OR, ID, CA, AK)
- **Purpose**: This repository contains the Nextstrain build for Pacific Flyway genomic surveillance of H5N1

## Table of Contents
- [Getting Started](#getting-started)
  - [Data Sources & Inputs](#data-sources--inputs)
  - [Setup & Dependencies](#setup--dependencies)
    - [Installation](#installation)
    - [Clone the repository](#clone-the-repository)
- [Run the Build with Test Data](#run-the-build-with-test-data)
- [Repository File Structure Overview](#repository-file-structure-overview)
- [Expected Outputs and Interpretation](#expected-outputs-and-interpretation)
- [Scientific Decisions](#scientific-decisions)
- [Adapting for Another State](#adapting-for-another-state)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Getting Started
This build was put together due to the need for Pacific Flyway H5N1 surveillance tool that was not previously available.

Some high-level build features and capabilities are:
- **Furin Cleavage Site Identification**: The Auspice color-by options includes two furin cleavage site labels: the furin cleavage site motifs are labeled as present, absent, or missing and the furin cleavage site sequences (the four bases preceding HA2) are labeled in the tree.

### Data Sources & Inputs
This build relies on publicly available data sourced from GISAID. These data have been cleaned and stored on AWS.

- **Sequence Data**: GISAID
- **Metadata**: Sample collection metadata from GISAID
- **Expected Inputs**:
    - fasta files: (containing viral genome sequences per segment of genome)
        - `data/fasta/pb2_sequences.fasta`
        - `data/fasta/pb1_sequences.fasta`
        - `data/fasta/pa_sequences.fasta`
        - `data/fasta/ha_sequences.fasta`
        - `data/fasta/np_sequences.fasta`
        - `data/fasta/na_sequences.fasta`
        - `data/fasta/mp_sequences.fasta`
        - `data/fasta/ns_sequences.fasta`             
    - metadata files:  (with relevant sample information)
        - `data/metadata/metadata.xlsx`

### Setup & Dependencies
#### Installation
Ensure that you have [Nextstrain](https://docs.nextstrain.org/en/latest/install.html) installed.

To check that Nextstrain is installed:
```
nextstrain check-setup
```
If Nextstrain is not installed, follow [Nextstrian installation guidelines](https://docs.nextstrain.org/en/latest/install.html)

#### Clone the repository:

```
git clone https://github.com/NW-PaGe/avian-flu-whole-genome.git
cd avian-flu-whole-genome
```

## Run the Build with Test Data
Test data coming soon.



## Repository File Structure Overview
The file structure of the repository is as follows with `*`" folders denoting folders that are the build's expected outputs.

```
.
├── config
├── auspice*
├── ingest
├── phylogenetic
├── scripts
├── data
├── example_data
└── results*
├── README.md
└── Snakefile
```

- `config/`: Contains the configuration .json file that defines how data should be presented in Auspice, the reference .gb file, the .tsv file to associate discrete values with colors in visualization.
- `ingest/`:
- `phylogenetic/`:
- `scripts/`: Contains python scripts that are called within the Snakefile.
 - `annotate-he-cleavage-site.py`: Python script that reads in HA alignment file, pulls out the 4 amino acid sites preceding HA2 and annotates the sequences for the furin cleavage site identification.
 - `join-genbank.py`:
 - `join-segments.py`: Python script that cleans and filters the metadata file.
- `data/`: Contains the most recent sequences and metadata to be used as input files. Contains and includes.txt and excludes.txt
- `example_data/`: Contains a subset of sequences and metadata sourced from NCBI to be used to test this build
- `Snakefile`: The Snakefile serves as the blueprint for defining and organizing the data processing workflow. It is a plain text file that contains a series of rules, each specifying how to transform input files into output files.

<!-- - - `clade-labeling`: Currently not used in this build. -->


## Expected Outputs and Interpretation
Running the build with the provided fasta and metadata file in `example_data`, the runtime using a 32.0 GB computer with 4 cores should take approximately XX minutes. After successfully running the build with test data, there will be two output folders containing the build results.


- `auspice/` folder contains:
  - `flu_avian_h5n1_ha.json` : JSON file to be visualized in Auspice
- `results/` folder contains:
  - `include/`: Text files of subsampled sequences to include and a fasta file of sequences to include in build
  - Intermediate files generated from build

## Scientific Decisions
- **Reference selection**: [A/Goose/Guangdong/1/96(H5N1)](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=93838) is used as the reference because it was the first identified H5N1 subtype.
- **Furin cleavage site**:`scripts/annotate-ha-cleavage-site.py` is used by the rule cleavage_site to determine the sequence of amino acids at the HA cleavage site and annotate those sequences for whether they contain a furin cleavage site. This will show up on the Color By drop down as "furin cleavage motif" and be colored as present, absent, or missing data. A furin cleavage motif addition preceding the HA cleavage site may result in viral replication across a range of tissues as well as being one of the prime determinants of avian influenza virulence.
- **Other adjustments**:
  - `config/includes.txt`: These sequences are always included into our sampling strategy as they are relevant to our epidemiological investigations.
  - `config/excludes.txt`: These sequences are always excluded from our subsampling and filtering due to duplication and based on epidemiological linkage knowledge.


## Contributing
For any questions please submit them to our [Discussions](https://github.com/NW-PaGe/avian-flu-whole-genome/discussions) page otherwise software issues and requests can be logged as a Git [Issue](https://github.com/NW-PaGe/avian-flu-whole-genome/issues).

## License
This project is licensed under a modified GPL-3.0 License.
You may use, modify, and distribute this work, but commercial use is strictly prohibited without prior written permission.

## Acknowledgements

This work is made possible by the open sharing of genetic data by research groups from all over the world. We gratefully acknowledge their contributions.  Special thanks to Washington Animal Disease Diagnostic Laboratory (WADDL) and AMD collaborators.
