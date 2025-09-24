process GIT_CLONEMSISENSOR2MODEL {
    label 'process_single'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/09/09d674a91a6f798d46016fe39b89c13b08afc35d0a455980006879bf1d5228cb/data':
        'community.wave.seqera.io/library/git:2.51.0--bd70ff2445f3ae66' }"

    input:
    val model

    output:
    path "model/*", emit: model
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def models = [hg38: 'models_hg38', hg19: 'models_hg19_GRCh37', b37: 'models_b37_HumanG1Kv37']
    def model_name = models.get(model)
    if (!model_name) {
        throw new IllegalArgumentException("Unsupported model: ${model}. Supported models are: ${models.keySet().join(', ')}")
    }
    """
    git \\
        clone \\
        ${args} \\
        https://github.com/niu-lab/msisensor2.git

    mv -v msisensor2/${model_name} model

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        git: \$(git --version | sed -e 's/(.*//' -e 's/git version //')
    END_VERSIONS
    """

    stub:
    """
    mkdir model

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        git: \$(git --version | sed -e 's/(.*//' -e 's/git version //')
    END_VERSIONS
    """
}
