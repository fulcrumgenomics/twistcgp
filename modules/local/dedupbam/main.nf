process DEDUPBAM {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/64/64e8f594b6f0dd879bc5abbe4ca70b6b761e1920e407d9e1c7d27b89004aac34/data':
        'community.wave.seqera.io/library/fgumi:0.5.0--a2d14bf52f73eaef' }"

    input:
    tuple val(meta), path(template_coordinate_bam)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.bam.bai"), emit: bai
    tuple val(meta), path("*.bam"), path("*.bam.bai"), emit: bam_bai
    tuple val(meta), path("*.metrics.txt"), emit: metrics
    tuple val(meta), path("*.family_size_histogram.txt"), emit: histogram
    tuple val("${task.process}"), val('fgumi'), eval("fgumi --version | sed 's/^fgumi //'"), topic: versions, emit: versions_fgumi

    when:
    task.ext.when == null || task.ext.when

    script:
    def fgumi_dedup_args = task.ext.fgumi_dedup_args ?: ''
    def fgumi_sort_args = task.ext.fgumi_sort_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    if ("${template_coordinate_bam}" == "${prefix}.bam") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }

    // fgumi dedup has no `-` stdout mode, but it writes BGZF to /dev/stdout and logs to stderr,
    // so the pipe carries only the BAM. Uncompressed, since the sort recompresses.
    """
    fgumi dedup \\
        --input ${template_coordinate_bam} \\
        --output /dev/stdout \\
        --metrics ${prefix}.metrics.txt \\
        --family-size-histogram ${prefix}.family_size_histogram.txt \\
        --compression-level 0 \\
        --threads ${task.cpus} \\
        ${fgumi_dedup_args} \\
        | fgumi sort \\
            --input - \\
            --output ${prefix}.bam \\
            --order coordinate \\
            --write-index \\
            --threads ${task.cpus} \\
            ${fgumi_sort_args}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    if ("${template_coordinate_bam}" == "${prefix}.bam") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }
    """
    touch ${prefix}.bam
    touch ${prefix}.bam.bai
    touch ${prefix}.metrics.txt
    touch ${prefix}.family_size_histogram.txt
    """
}
