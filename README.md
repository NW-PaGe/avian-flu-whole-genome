# avian-flu-whole-genome
avian flu whole genome Nextstrain build

## Build Overview
- **Build Name**: Pacific Flyway Avian Influenza Whole Genome Build
- **Pathogen/Strain**: Influenza A H5N1
- **Scope**: Pacific Flyway (BC, WA, OR, ID, CA, AK)
- **Purpose**: This repository contains the Nextstrain build for Pacific Flyway genomic surveillance of avian-flu. It allows for segment-specific and whole genome analysis with flexible multi-build configuration.

## Table of Contents
- [Pathogen Epidemiology](#pathogen-epidemiology)
- [Scientific Decisions](#scientific-decisions)
- [Getting Started](#getting-started)
  - [Data Sources & Inputs](#data-sources--inputs)
  - [Setup & Dependencies](#setup--dependencies)
    - [Installation](#installation)
    - [Clone the repository](#clone-the-repository)
- [Multi-Build Configuration System](#multi-build-configuration-system)
  - [Configuration Structure](#configuration-structure)
  - [Build Examples](#build-examples)
  - [Advanced Configuration](#advanced-configuration)
- [Run the Build](#run-the-build)
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

  - **Multi-build configuration**: Define multiple phylogenetic builds in a single configuration file, each with different segment combinations, geographic focus, and sampling strategies.

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

## Multi-Build Configuration System

This build uses a flexible configuration system that allows you to define multiple phylogenetic analyses in a single configuration file. Each build can have different segment combinations, geographic focus, and sampling strategies.

### Configuration Structure

The configuration file uses the following structure:

```yaml
# Global settings
strain_id_field: strain

# Define multiple builds
builds:
  build-name-1:
    subtype: h5n1
    segments: [ha]
    files:
      # File paths (can use {subtype} and {segment} placeholders)
    subsample:
      # Sampling strategy
  
  build-name-2:
    subtype: h5n1  
    segments: [pb2, pb1, pa, ha, np, na, mp, ns]
    files:
      # File paths
    subsample:
      # Different sampling strategy
```

#### File Organization by Subtype
Use the `{subtype}` placeholder to organize reference files by subtype:

```yaml
files:
  reference_files: "config/{subtype}/reference_h5n1_{segment}.gb"
  sequences: "test_data/fasta/{segment}_sequences.fasta"
```

This allows directory structures like:
```
config/
├── h5n1/
│   ├── reference_h5n1_ha.gb
│   └── reference_h5n1_na.gb
└── h5nx/
    ├── reference_h5n1_ha.gb
    └── reference_h5n1_na.gb
```

### Key Features

- **Automatic concatenation**: Multi-segment builds automatically concatenate segments in the order specified
- **Single-segment optimization**: Single-segment builds automatically skip concatenation
- **Flexible file paths**: Use `{subtype}` and `{segment}` placeholders for organized file structures
- **Independent sampling**: Each build can have completely different sampling strategies
- **Scalable**: Add new builds by simply adding entries to the configuration file

## Run the Build

### Run All Builds
```bash
nextstrain build . --configfile phylogenetic/build-configs/wa-config-augur-sub-testing.yaml
```

### Run Specific Build
```bash
nextstrain build . --configfile phylogenetic/build-configs/wa-config-augur-sub-testing.yaml auspice/h5n1-ha-only.json
```

### Run Multiple Specific Builds
```bash
nextstrain build . --configfile phylogenetic/build-configs/wa-config-augur-sub-testing.yaml auspice/h5n1-ha-only.json auspice/h5n1-whole-genome.json
```

### Dry Run (Check Configuration)
```bash
nextstrain build . --configfile phylogenetic/build-configs/wa-config-augur-sub-testing.yaml --dry-run
```

## Repository File Structure Overview
The file structure of the repository is as follows with `*` folders denoting folders that are the build's expected outputs.

```
.
├── config/
│   ├── h5n1/                     # Subtype-specific references
│   │   ├── reference_h5n1_*.gb
│   │   └── colors_h5n1.tsv
│   └── auspice_config_*.json
├── auspice*/                     # Final JSON outputs
├── phylogenetic/
│   └── build-configs/           # Configuration files
├── scripts/
├── test_data/
│   ├── fasta/
│   └── metadata/
├── results*/                    # Intermediate outputs
├── README.md
└── Snakefile
```

## Expected Outputs and Interpretation
Running the build with the provided fasta and metadata file in `test_data`, the runtime using a 32.0 GB computer with 4 cores should take approximately XX minutes. After successfully running the build with test data, there will be output folders containing the build results.

- `auspice/` folder contains:
  - `h5n1-ha-only.json` : HA-only phylogeny
  - `h5n1-surface-proteins.json` : HA-NA concatenated phylogeny
  - `h5n1-whole-genome.json` : Whole genome phylogeny
- `results/` folder contains:
  - `{build-name}/`: Folder for each build containing intermediate files
      - `genome/filtered_metadata_{segment}.tsv` : Filtered metadata per segment
      - `genome/sequences_{segment}.fasta` : Filtered sequences per segment
      - `genome/aligned_{segment}.fasta` : Aligned sequences per segment
      - `genome/aligned_final.fasta` : Final concatenated alignment (if applicable)

## Customization for Local Adaptation

### Adding New Builds
To add a new build, simply add an entry to your configuration file:

```yaml
builds:
  # ... existing builds ...
  
  your-new-build:
    subtype: h5n1
    segments: [pa, ha]  # Custom segment combination
    files:
      reference_files: "config/{subtype}/reference_h5n1_{segment}.gb"
      sequences: "your_data/fasta/{segment}_sequences.fasta"
      metadata: "your_data/metadata.tsv"
      colors: "config/colors_custom.tsv"
      auspice_config: "config/auspice_config_custom.json"
    subsample:
      defaults:
        exclude_ambiguous_dates_by: year
      samples:
        your_region:
          query: division == 'Your State'
          max_sequences: 150
```

### Modifying Geographic Focus
Update the `query` parameters in the `subsample` section to focus on your region of interest.

### Adding New Subtypes
Organize reference files by subtype using the `{subtype}` placeholder and create appropriate directory structures.

## Contributing
For any questions please submit them to our [Discussions](https://github.com/NW-PaGe/avian-flu-whole-genome/discussions) page otherwise software issues and requests can be logged as a Git [Issue](https://github.com/NW-PaGe/avian-flu-whole-genome/issues).

## License
This project is licensed under a modified GPL-3.0 License.
You may use, modify, and distribute this work, but commercial use is strictly prohibited without prior written permission.

## Acknowledgements

This work is made possible by the open sharing of genetic data by research groups from all over the world. We gratefully acknowledge their contributions. Special thanks to Washington Animal Disease Diagnostic Laboratory (WADDL) and AMD collaborators.
