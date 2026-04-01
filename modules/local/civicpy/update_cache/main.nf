process CIVICPY_UPDATE_CACHE {
    label 'process_single'

    conda "${moduleDir}/../annotate/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/civicpy:5.2.0--pyhdfd78af_0'
        : 'docker.io/griffithlab/civicpy:v5.2.0' }"

    output:
    path "civicpy_cache.pkl", emit: cache
    path "versions.yml",      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export CIVICPY_CACHE_FILE=\$PWD/civicpy_cache.pkl

    civicpy update

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        civicpy: \$(civicpy --version | sed 's/.*version //')
    END_VERSIONS
    """

    stub:
    """
    touch civicpy_cache.pkl

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        civicpy: \$(civicpy --version | sed 's/.*version //')
    END_VERSIONS
    """
}
