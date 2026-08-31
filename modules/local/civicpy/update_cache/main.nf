process CIVICPY_UPDATE_CACHE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/civicpy:5.4.0--pyhdfd78af_0'
        : 'docker.io/griffithlab/civicpy:v5.4.0' }"

    output:
    path "civicpy_cache.pkl", emit: cache
    tuple val("${task.process}"), val('civicpy'), eval("civicpy --version | sed 's/.*version //'"), topic: versions, emit: versions_civicpy
    tuple val("${task.process}"), val('civic_db_release'), eval("cat civic_db_release.txt"), topic: versions, emit: versions_civic_db

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export CIVICPY_CACHE_FILE=\$PWD/civicpy_cache.pkl

    civicpy update

    # Record the CIViC knowledgebase snapshot date that civicpy stores in the cache
    # (CACHE['full_cached']); degrade to 'unknown' rather than fail the task if it is absent.
    civic_release=\$(python3 -c "import pickle; d = pickle.load(open('civicpy_cache.pkl', 'rb')).get('full_cached'); print(d.date().isoformat() if d else 'unknown')" 2>/dev/null || echo unknown)
    echo "\${civic_release}" > civic_db_release.txt
    """

    stub:
    """
    touch civicpy_cache.pkl
    echo 'unknown' > civic_db_release.txt
    """
}
