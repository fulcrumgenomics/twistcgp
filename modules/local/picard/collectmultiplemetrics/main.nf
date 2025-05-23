process PICARD_COLLECTMULTIPLEMETRICS {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.3.0--hdfd78af_0' :
        'biocontainers/picard:3.3.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(bai)
    tuple val(ref_meta), path(fasta)
    tuple val(ref_meta1), path(fai)

    output:
    tuple val(meta), path("*metrics.txt"), emit: metrics
    tuple val(meta), path("*.pdf"), emit: pdfs, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--REFERENCE_SEQUENCE ${fasta}" : ""
    def avail_mem = 3072
    if (!task.memory) {
        log.info('[Picard CollectMultipleMetrics] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.')
    }
    else {
        avail_mem = (task.memory.mega * 0.8).intValue()
    }
    """
    picard \\
        -Xmx${avail_mem}M \\
        CollectMultipleMetrics \\
        ${args} \\
        --INPUT ${bam} \\
        --FILE_EXTENSION ".txt" \\
        --PROGRAM CollectAlignmentSummaryMetrics \\
        --PROGRAM CollectBaseDistributionByCycle \\
        --PROGRAM CollectGcBiasMetrics \\
        --PROGRAM CollectInsertSizeMetrics \\
        --PROGRAM CollectQualityYieldMetrics \\
        --PROGRAM CollectSequencingArtifactMetrics \\
        --PROGRAM MeanQualityByCycle \\
        --PROGRAM QualityScoreDistribution \\
        --OUTPUT ${prefix}.CollectMultipleMetrics \\
        ${reference}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(picard CollectMultipleMetrics --version 2>&1 | grep -o 'Version.*' | cut -f2- -d:)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.CollectMultipleMetrics.alignment_summary_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.bait_bias_detail_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.bait_bias_summary_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.base_distribution_by_cycle.pdf
    touch ${prefix}.CollectMultipleMetrics.base_distribution_by_cycle_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.error_summary_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.gc_bias.detail_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.gc_bias.pdf
    touch ${prefix}.CollectMultipleMetrics.gc_bias.summary_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.pre_adapter_detail_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.pre_adapter_summary_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.quality_by_cycle.pdf
    touch ${prefix}.CollectMultipleMetrics.quality_by_cycle_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.quality_distribution.pdf
    touch ${prefix}.CollectMultipleMetrics.quality_distribution_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.quality_yield_metrics.txt
    touch ${prefix}.CollectMultipleMetrics.read_length_histogram.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard CollectMultipleMetrics --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}
