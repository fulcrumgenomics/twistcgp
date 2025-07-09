process TMB {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/tmb:1.3.0--pyh5e36f6f_0'
        : 'quay.io/biocontainers/tmb:1.3.0--pyh5e36f6f_0'}"

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(targets)
    path tmb_snpeff_config
    path tmb_mutect2_config

    output:
    tuple val(meta), path("*.log"), emit: log
    tuple val(meta), path ("*_export.vcf"), emit: vcf
    // export a VCF with the considered variants
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def targets_bed = targets ? "--bed ${targets}" : ''
    def target_region = args.contains("--effGenomeSize") ? '' : targets_bed
    """
    pyTMB.py -i ${vcf} \\
        --dbConfig ${tmb_snpeff_config} \\
        --varConfig ${tmb_mutect2_config} \\
        ${target_region} \\
        ${args} \\
        --export \\
        > ${prefix}.tmb.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tmb: \$(echo \$(pyTMB.py --version 2>&1) | sed 's/^.*pyTMB.py //; s/.*\$//' | sed 's|[()]||g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.tmb.log
    touch ${prefix}_export.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tmb: \$(echo \$(pyTMB.py --version 2>&1) | sed 's/^.*pyTMB.py //; s/.*\$//' | sed 's|[()]||g')
    END_VERSIONS
    """
}
