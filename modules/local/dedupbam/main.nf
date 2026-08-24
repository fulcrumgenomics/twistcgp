process DEDUPBAM {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f4/f4572bb91e8e6437471c9c83b57d1b5b46d7ed6c19c99033aee430e1e3f29471/data':
        'community.wave.seqera.io/library/fgumi_samtools:7264e10d93bcd131' }"

    input:
    tuple val(meta), path(template_coordinate_bam)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.bam.bai"), emit: bai
    tuple val(meta), path("*.bam"), path("*.bam.bai"), emit: bam_bai
    tuple val(meta), path("*.metrics.txt"), emit: metrics
    tuple val(meta), path("*.family_size_histogram.txt"), emit: histogram
    tuple val("${task.process}"), val('fgumi'), eval("fgumi --version | sed 's/^fgumi //'"), topic: versions, emit: versions_fgumi
    tuple val("${task.process}"), val('samtools'), eval("samtools --version | sed -n 's/^samtools //p'"), topic: versions, emit: versions_samtools

    when:
    task.ext.when == null || task.ext.when

    script:
    def fgumi_dedup_args = task.ext.fgumi_dedup_args ?: ''
    def fgumi_sort_args = task.ext.fgumi_sort_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    if ("${template_coordinate_bam}" == "${prefix}.bam") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }

    """
    fgumi dedup \\
        --input ${template_coordinate_bam} \\
        --output - \\
        --metrics ${prefix}.metrics.txt \\
        --family-size-histogram ${prefix}.family_size_histogram.txt \\
        --compression-level 0 \\
        --threads ${task.cpus} \\
        ${fgumi_dedup_args} \\
        | fgumi sort \\
            --input - \\
            --output ${prefix}.bam \\
            --order coordinate \\
            --threads ${task.cpus} \\
            ${fgumi_sort_args}

    samtools index -@ ${task.cpus} ${prefix}.bam
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
