import os

# Check if config was already loaded via --configfile flag
# If config is empty, load the default
if not config:
    configfile: os.path.join(workflow.basedir, "phylogenetic/build-configs/wa-config-augur-sub.yaml")

# Store the config file path for use in rules
CONFIG_FILE = workflow.overwrite_configfiles[0] if workflow.overwrite_configfiles else os.path.join(workflow.basedir, "phylogenetic/build-configs/wa-config-augur-sub.yaml")

# Extract all build names from config
BUILD_NAMES = list(config.get("builds", {}).keys())
if not BUILD_NAMES:
    raise ValueError("No builds defined in config file. Please define at least one build under 'builds:'")

# Helper functions to access build-specific configuration
def get_build_config(build_name, key, default=None):
    """Get a configuration value for a specific build"""
    return config["builds"][build_name].get(key, default)

def get_segments(wildcards):
    """Get the list of segments for a build"""
    return config["builds"][wildcards.build_name]["segments"]

def should_concatenate(wildcards):
    build_conf = config["builds"][wildcards.build_name]
    segments = build_conf["segments"]

    # Single segment - never concatenate
    if len(segments) == 1:
        return False

    # Multiple segments - default to concatenate unless explicitly disabled
    return build_conf.get("concatenate", True)

def subtype(build_name):
    """Get the subtype for a build"""
    return config["builds"][build_name]["subtype"]

# Simple output naming - just use build name
rule all:
    input:
        expand("auspice/{build_name}.json", build_name=BUILD_NAMES)

# Dynamic rule to access files for each build
def get_build_files(wildcards, file_key):
    """Get file path for a specific build and file key"""
    build_conf = config["builds"][wildcards.build_name]
    file_path = build_conf["files"][file_key]

    # Handle subtype wildcard if present
    if "{subtype}" in file_path:
        build_subtype = build_conf["subtype"]
        file_path = file_path.replace("{subtype}", build_subtype)

    # Handle segment wildcard if present
    if "{segment}" in file_path and hasattr(wildcards, "segment"):
        file_path = file_path.replace("{segment}", wildcards.segment)

    return file_path

rule filter:
    """
    Filtering using augur subsample
    """
    input:
        sequences = lambda w: get_build_files(w, "sequences"),
        metadata = lambda w: get_build_files(w, "metadata"),
        #include = lambda w: get_build_files(w, "include"),
        #exclude = lambda w: get_build_files(w, "exclude"),
    output:
        sequences = "results/{build_name}/genome/sequences_{segment}.fasta",
        metadata = "results/{build_name}/genome/filtered_metadata_{segment}.tsv"
    params:
        config = CONFIG_FILE,
        config_section = lambda w: ["builds", w.build_name, "subsample"],
        strain_id = lambda w: config.get("strain_id_field", "strain")
    log:
        "logs/{build_name}/genome/sequences_{segment}.txt"
    shell:
        """
        augur subsample \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --config "{params.config}" \
            --config-section {params.config_section:q} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} \
            --output-log {log}
        """

rule align:
    input:
        sequences ="results/{build_name}/genome/sequences_{segment}.fasta",
        reference = lambda w: get_build_files(w, "reference_files"),
    output:
        alignment = "results/{build_name}/genome/aligned_{segment}.fasta",
    threads:
        8
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.reference} \
            --output {output.alignment} \
            --remove-reference \
            --fill-gaps \
            --nthreads {threads}
        """


def get_alignment_input(wildcards):
    """
    Return appropriate alignment input based on whether concatenation is needed
    """
    segments = get_segments(wildcards)
    if should_concatenate(wildcards):
        # Multiple segments - need concatenation
        return expand("results/{{build_name}}/genome/aligned_{segment}.fasta",
                     segment=segments)
    else:
        # Single segment - use it directly
        return f"results/{wildcards.build_name}/genome/aligned_{segments[0]}.fasta"


rule prepare_alignment:
    """
    Either concatenate multiple segments or copy single segment alignment
    """
    input:
        alignment = lambda w: get_alignment_input(w)
    output:
        alignment = "results/{build_name}/genome/aligned_final.fasta",
    params:
        concatenate = lambda w: should_concatenate(w)
    run:
        if params.concatenate:
            # Concatenate multiple segments
            shell("""
                python scripts/join-segments.py \
                    --segments {input.alignment} \
                    --output "{output.alignment}"
            """)
        else:
            # Single segment - just copy/symlink
            shell('cp "{input.alignment}" "{output.alignment}"')


def get_genbank_input(wildcards):
    """Get genbank files for concatenation"""
    segments = get_segments(wildcards)
    build_conf = config["builds"][wildcards.build_name]

    # Get the reference file pattern from config
    ref_pattern = build_conf["files"]["reference_files"]

    # Substitute subtype if present in the pattern
    if "{subtype}" in ref_pattern:
        build_subtype = build_conf["subtype"]
        ref_pattern = ref_pattern.replace("{subtype}", build_subtype)

    # Generate file paths for each segment
    genbank_files = []
    for segment in segments:
        if "{segment}" in ref_pattern:
            file_path = ref_pattern.replace("{segment}", segment)
        else:
            file_path = ref_pattern
        genbank_files.append(file_path)

    return genbank_files

rule prepare_genbank:
    """
    Either concatenate multiple segment genbank files or copy single segment
    """
    input:
        genbank_files = lambda w: get_genbank_input(w)
    output:
        genbank = "results/{build_name}/genome/reference.gb",
    params:
        concatenate = lambda w: should_concatenate(w)
    run:
        if params.concatenate:
            # Concatenate multiple genbank files
            shell("""
                python scripts/join-genbank.py \
                    --genbank {input.genbank_files} \
                    --output "{output.genbank}"
            """)
        else:
            # Single segment - just copy
            shell('cp "{input.genbank_files}" "{output.genbank}"')


rule tree:
    message: "Building tree"
    input:
        alignment = "results/{build_name}/genome/aligned_final.fasta",
    output:
        tree = "results/{build_name}/genome/tree-raw.nwk",
    params:
        method = "iqtree"
    threads:
        8
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --method {params.method} \
            --nthreads {threads} \
            --override-default-args
        """


def clock_rate(w):
    """
    Calculate clock rate based on segments in the build.
    Returns empty string if use_fixed_clock is False, allowing augur to estimate rate from data.
    """
    build_conf = config["builds"][w.build_name]
    
    # Check if we should use fixed clock
    if not build_conf.get("use_fixed_clock", True):
        return ""  # Let augur estimate rate from data
    
    # Calculate fixed rate for builds that specify use_fixed_clock: true
    st = subtype(w.build_name)
    # Allow H5Nx subtypes (individual subtypes and the h5nx grouping)
    allowed_subtypes = ('h5nx', 'h5n1', 'h5n2', 'h5n3', 'h5n4', 'h5n5', 'h5n6', 'h5n7', 'h5n8', 'h5n9')
    assert st in allowed_subtypes, \
        f'Clock rates only available for H5Nx subtypes, got {st}'

    clock_rates_h5nx = {
        'pb2': 0.00287,
        'pb1': 0.00264,
        'pa':  0.00248,
        'ha':  0.00455,
        'np':  0.00252,
        'na':  0.00349,
        'mp':  0.00191,
        'ns':  0.00249,
    }
    lengths = {
        'pb2': 2341,
        'pb1': 2341,
        'pa':  2233,
        'ha':  1760,
        'np':  1565,
        'na':  1458,
        'mp':  1027,
        'ns':  865,
    }

    # Get segments for this build
    segments = get_segments(w)

    # Calculate weighted average clock rate based on segments in this build
    total_length = sum(lengths[seg] for seg in segments)
    mean = sum(clock_rates_h5nx[seg] * lengths[seg] for seg in segments) / total_length
    stdev = mean / 2
    return f"--clock-rate {mean:.6f} --clock-std-dev {stdev:.6f}"

rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - use {params.coalescent} coalescent timescale
          - estimate {params.date_inference} node dates
        """
    input:
        tree = "results/{build_name}/genome/tree-raw.nwk",
        alignment = "results/{build_name}/genome/aligned_final.fasta",
        metadata = lambda w: get_build_files(w, "metadata"),
    output:
        tree = "results/{build_name}/genome/tree.nwk",
        node_data = "results/{build_name}/genome/branch-lengths.json"
    params:
        coalescent = "const",
        date_inference = "marginal",
        clock_rate = clock_rate,
        clock_filter_iqd = 4,
        root_method = "best",
        strain_id = lambda w: config.get("strain_id_field", "strain")

    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            --keep-polytomies \
            --root {params.root_method} \
            --coalescent {params.coalescent} \
            --date-confidence \
            --date-inference {params.date_inference} \
            --clock-filter-iqd {params.clock_filter_iqd} \
            {params.clock_rate}
        """


rule ancestral:
    input:
        tree = "results/{build_name}/genome/tree.nwk",
        alignment = "results/{build_name}/genome/aligned_final.fasta",
    output:
        node_data = "results/{build_name}/genome/nt-muts.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference} \
            --keep-ambiguous
        """


rule translate:
    message: "Translating amino acid sequences"
    input:
        tree = "results/{build_name}/genome/tree.nwk",
        node_data = "results/{build_name}/genome/nt-muts.json",
        reference = "results/{build_name}/genome/reference.gb",
    output:
        node_data = "results/{build_name}/genome/aa-muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output {output.node_data}
        """


rule traits:
    message: "Inferring ancestral traits for {params.columns!s}"
    input:
        tree = rules.refine.output.tree,
        metadata = lambda w: get_build_files(w, "metadata")
    output:
        node_data = "results/{build_name}/genome/traits.json"
    params:
        columns = 'host',
        sampling_bias_correction = 5
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --output {output.node_data} \
            --columns {params.columns} \
            --sampling-bias-correction {params.sampling_bias_correction} \
            --confidence
        """


def get_cleavage_site_input(wildcards):
    """Only get HA alignment if HA is in the build's segments"""
    segments = get_segments(wildcards)
    if 'ha' in segments:
        return f"results/{wildcards.build_name}/genome/aligned_ha.fasta"
    else:
        # Return empty - rule won't run for builds without HA
        return []


rule cleavage_site:
    """
    Annotate HA cleavage site - only runs if HA is in the segment list
    """
    input:
        ha_alignment = lambda w: get_cleavage_site_input(w)
    output:
        cleavage_site_annotations = "results/{build_name}/genome/cleavage-site_ha.json",
        cleavage_site_sequences = "results/{build_name}/genome/cleavage-site-sequences_ha.json"
    run:
        if input.ha_alignment:
            shell("""
                python scripts/annotate-ha-cleavage-site.py \
                    --alignment "{input.ha_alignment}" \
                    --furin_site_motif "{output.cleavage_site_annotations}" \
                    --cleavage_site_sequence "{output.cleavage_site_sequences}"
            """)
        else:
            # Create empty JSON files for builds without HA
            shell("""
                echo '{{}}' > "{output.cleavage_site_annotations}"
                echo '{{}}' > "{output.cleavage_site_sequences}"
            """)


def get_export_node_data(wildcards):
    """Get node data files, including cleavage site only if HA is present"""
    node_data = [
        f"results/{wildcards.build_name}/genome/branch-lengths.json",
        f"results/{wildcards.build_name}/genome/nt-muts.json",
        f"results/{wildcards.build_name}/genome/aa-muts.json",
        f"results/{wildcards.build_name}/genome/traits.json"
    ]

    # Only add cleavage site files if HA is in segments
    segments = get_segments(wildcards)
    if 'ha' in segments:
        node_data.extend([
            f"results/{wildcards.build_name}/genome/cleavage-site_ha.json",
            f"results/{wildcards.build_name}/genome/cleavage-site-sequences_ha.json"
        ])

    return node_data


rule export:
    input:
        tree = "results/{build_name}/genome/tree.nwk",
        metadata = lambda w: get_build_files(w, "metadata"),
        node_data = lambda w: get_export_node_data(w),
        colors = lambda w: get_build_files(w, "colors"),
        auspice_config = lambda w: get_build_files(w, "auspice_config"),
    output:
        auspice_json = "auspice/{build_name}.json"
    shell:
        """
        mkdir -p auspice
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.node_data} \
            --colors {input.colors} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence-inline \
            --output {output.auspice_json}
        """
