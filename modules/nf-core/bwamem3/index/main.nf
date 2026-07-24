process BWAMEM3_INDEX {
    tag "${meta.id}"
    label 'process_high'
    // bwa-mem3 builds an FM-index with libsais; peak memory scales with the reference
    // *sequence* length. fasta.size() is the on-disk size, so for a bgzipped reference
    // estimate the decompressed length (~4x) to avoid under-provisioning the index build.
    memory {
        def bases = fasta.name.endsWith('.gz') ? fasta.size() * 4 : fasta.size()
        280.MB * Math.ceil(bases / 10000000) * task.attempt
    }

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b1/b11b8a7f3944d27f0f4e9a10daac5750431dd9640cb196859f0f47bb8b60ac87/data'
        : 'community.wave.seqera.io/library/bwa-mem3:0.6.0--0742be28f9ae47ae'}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("bwamem3"), emit: index
    tuple val("${task.process}"), val('bwamem3'), eval("bwa-mem3 version | sed -nE '1 s/^([0-9]+(\\.[0-9]+)+).*/\\1/p'"), emit: versions_bwamem3, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${fasta}"
    def args = task.ext.args ?: ''
    """
    mkdir bwamem3
    bwa-mem3 \\
        index \\
        $args \\
        -t ${task.cpus} \\
        -p bwamem3/${prefix} \\
        $fasta
    """

    stub:
    def prefix = task.ext.prefix ?: "${fasta}"
    """
    mkdir bwamem3
    touch bwamem3/${prefix}.amb
    touch bwamem3/${prefix}.ann
    touch bwamem3/${prefix}.bwt.2bit.64
    touch bwamem3/${prefix}.pac
    """
}
