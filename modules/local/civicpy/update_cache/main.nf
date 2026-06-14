process CIVICPY_UPDATE_CACHE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/civicpy:5.4.0--pyhdfd78af_0'
        : 'docker.io/griffithlab/civicpy:v5.4.0' }"

    output:
    path "civicpy_cache.pkl", emit: cache
    tuple val("${task.process}"), val('civicpy'), eval("civicpy --version | sed 's/.*version //'"), topic: versions, emit: versions_civicpy

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export CIVICPY_CACHE_FILE=\$PWD/civicpy_cache.pkl

    civicpy update
    """

    stub:
    """
    touch civicpy_cache.pkl
    """
}
