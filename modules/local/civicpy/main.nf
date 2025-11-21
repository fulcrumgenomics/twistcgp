process CIVICPY {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/civicpy:5.1.0--pyhdfd78af_0'
        : 'docker.io/griffithlab/civicpy:5.1.0' }"

    input:
    tuple val(meta), path(vcf), path(tbi)
    val annotation_genome_version

    output:
    tuple val(meta), path("*.vcf"), emit: vcf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.civic"

    """
    export CIVICPY_CACHE_FILE=\$PWD/.civicpy

    civicpy annotate-vcf --input-vcf ${vcf} \\
        --output-vcf ${prefix}.vcf \\
        --reference ${annotation_genome_version} \\
        --include-status accepted

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        civicpy: \$(civicpy --version | sed 's/.*version //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        civicpy: \$(civicpy --version | sed 's/.*version //')
    END_VERSIONS
    """
}
