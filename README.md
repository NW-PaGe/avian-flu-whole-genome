# avian-flu-whole-genome
avian flu whole genome Nextstrain build

## Build Overview
- **Build Name**: Pacific Flyway Avian Influenza Whole Genome Build
- **Pathogen/Strain**: Influenza A H5N1
- **Scope**: Pacific Flyway (BC, WA, OR, ID, CA, AK)
- **Purpose**: This repository contains the Nextstrain build for Pacific Flyway genomic surveillance of avian-flu. It allows for segment-specific and whole genome analysis.

## Table of Contents
- [Pathogen Epidemiology](#pathogen-epidemiology)
- [Scientific Decisions](#scientific-decisions)
- [Getting Started](#getting-started)
  - [Data Sources & Inputs](#data-sources--inputs)
  - [Setup & Dependencies](#setup--dependencies)
    - [Installation](#installation)
    - [Clone the repository](#clone-the-repository)
- [Run the Build](#run-the-build-with-test-data)
  - [Expected Outputs](#expected-outputs)
  - [Visualizing Results](#visualize-results)
- [Customization for Local Adaptation](#customization-for-local-adaptation)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Pathogen Epidemiology
<!--
- Overview:
  - Pathogen type and family
  - Key subtypes/lineages relevant to the build
  - Mode(s) of transmission
- Nomenclature
- Geographic Distribution and Seasonality
  - Summarize where the pathogen has been found globally and/or in the region
  - Any seasonality patterns

- Public health importance
  - Why does surveillance matter for this pathogen.
- Genomic Relevance
  - Why are genomic data useful for this pathogen:
    - detecting lineage shifts
    - detecting emergence of variants
    - outbreak investigations
    - monitoring vaccine escape or antiviral resistance
    - understanding transmission pathways

- Additional Resources
  - Link any additional resources that are helpful in learning about this pathogen
  - Link Pathogen Genomic Profile if we have one created

  -->

## Scientific Decisions
  - **Reference selection**:
    - H5N1: [A/Goose/Guangdong/1/96(H5N1)](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=93838) is used as the reference because it was the first identified H5N1 subtype.
    - H5Nx:
    - H7N9:
    - H9N2:
  - **Furin cleavage site**:`scripts/annotate-ha-cleavage-site.py` is used by the rule cleavage_site to determine the sequence of amino acids at the HA cleavage site and annotate those sequences for whether they contain a furin cleavage site. This will show up on the Color By drop down as "furin cleavage motif" and be colored as present, absent, or missing data. A furin cleavage motif addition preceding the HA cleavage site may result in viral replication across a range of tissues as well as being one of the prime determinants of avian influenza virulence.
  - **Other adjustments**:
    - `config/includes.txt`: These sequences are always included into our sampling strategy as they are relevant to our epidemiological investigations.
    - `config/excludes.txt`: These sequences are always excluded from our subsampling and filtering due to duplication and based on epidemiological linkage knowledge.  

## Getting Started
This build was put together due to the need for Pacific Flyway H5N1 surveillance tool that was not previously available.

Some high-level build features and capabilities are:

  - **Flexibility in segments**: This build has the flexibility to allow for a whole genome build, as well as single segment and segment combinations based on what is specified in the build config file.

  - **Furin Cleavage Site Identification**: The Auspice color-by options includes two furin cleavage site labels: the furin cleavage site motifs are labeled as present, absent, or missing and the furin cleavage site sequences (the four bases preceding HA2) are labeled in the tree.

### Data Sources & Inputs
This build relies on publicly available data sourced from GISAID. These data have been cleaned and stored on AWS.

- **Sequence Data**: GISAID
- **Metadata**: Sample collection metadata from GISAID
- **Expected Inputs**:
    - fasta files: (containing viral genome sequences per segment of genome)
        - `test_data/fasta/pb2_sequences.fasta`
        - `test_data/fasta/pb1_sequences.fasta`
        - `test_data/fasta/pa_sequences.fasta`
        - `test_data/fasta/ha_sequences.fasta`
        - `test_data/fasta/np_sequences.fasta`
        - `test_data/fasta/na_sequences.fasta`
        - `test_data/fasta/mp_sequences.fasta`
        - `test_data/fasta/ns_sequences.fasta`             
    - metadata files:  (with relevant sample information)
        - `test_data/metadata/merged_metadata.tsv`

### Setup & Dependencies
#### Installation
Ensure that you have [Nextstrain](https://docs.nextstrain.org/en/latest/install.html) installed.

To check that Nextstrain is installed:
```
nextstrain check-setup
```
If Nextstrain is not installed, follow [Nextstrain installation guidelines](https://docs.nextstrain.org/en/latest/install.html)

#### Clone the repository:

```
git clone https://github.com/NW-PaGe/avian-flu-whole-genome.git
cd avian-flu-whole-genome
```

## Run the Build with Test Data
```
nextstrain build .
```

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
├── test_data
├── results*
├── README.md
└── Snakefile
```
More details on the file structure of this build can be found [here](https://github.com/NW-PaGe/avian-flu-whole-genome/wiki/_new).

## Expected Outputs and Interpretation
Running the build with the provided fasta and metadata file in `test_data`, the runtime using a 32.0 GB computer with 4 cores should take approximately XX minutes. After successfully running the build with test data, there will be two output folders containing the build results.


- `auspice/` folder contains:
  - `flu_avian_h5n1_ha.json` : JSON file to be visualized in Auspice
- `results/` folder contains:
  - `HXNX-{build-resolution}/`: Folder named as the flu type (HXNX) and resolution (whole genome, segment HA. etc) specified in config file
      - `filtered_metadata_{segment}.tsv` Text file of subsampled sequences to include
      - `sequences_{segment}.fasta` Fasta file of sequences to include in build

## Contributing
For any questions please submit them to our [Discussions](https://github.com/NW-PaGe/avian-flu-whole-genome/discussions) page otherwise software issues and requests can be logged as a Git [Issue](https://github.com/NW-PaGe/avian-flu-whole-genome/issues).

## License
This project is licensed under a modified GPL-3.0 License.
You may use, modify, and distribute this work, but commercial use is strictly prohibited without prior written permission.

## Acknowledgements

This work is made possible by the open sharing of genetic data by research groups from all over the world. We gratefully acknowledge their contributions.  Special thanks to Washington Animal Disease Diagnostic Laboratory (WADDL) and AMD collaborators.
