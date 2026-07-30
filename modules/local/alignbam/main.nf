process ALIGNBAM {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b4/b482cd2a22b688627cf5888380181fa8f04bc013c3294afbe00cd03e95441f97/data':
        'community.wave.seqera.io/library/bwa-mem3_fgumi_samtools_findutils_coreutils:d5847203075663d7' }"

    input:
    tuple val(meta), path(unmapped_bam)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fasta_fai)
    tuple val(meta4), path(dict)
    tuple val(meta5), path(bwa_dir)
    val sort_type

    output:
    tuple val(meta), path("*.mapped.bam"), emit: bam
    tuple val(meta), path("*.mapped.bam.bai"), emit: bai, optional: true
    tuple val(meta), path("*.mapped.bam"), path("*.mapped.bam.bai"), emit: bam_bai, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def samtools_fastq_args = task.ext.samtools_fastq_args ?: ''
    def samtools_sort_args = task.ext.samtools_sort_args ?: ''
    def bwa_args = task.ext.bwa_args ?: ''
    def fgumi_zipper_args = task.ext.fgumi_zipper_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extra_command = ""
    // fgumi zipper manages its own memory (bounded template buffer), so no JVM heap sizing is needed.
    def zipper_output = ""
    def zipper_compression = 1

    if (sort_type == "none") {
        zipper_output = prefix + ".mapped.bam"
        zipper_compression = 1
    }
    else {
        // Write zipper output to an intermediate file and sort that file, rather than piping
        // through stdout. Sorting a real file is robust under both Docker and Singularity.
        zipper_output = prefix + ".zipped.bam"
        // uncompressed BGZF: this transient file is immediately re-read by samtools sort, so skip
        // the deflate/inflate round-trip.
        zipper_compression = 0
        extra_command = "samtools sort "
        extra_command += samtools_sort_args
        if (sort_type == "template-coordinate") {
            extra_command += " --template-coordinate"
        }
        else {
            if (sort_type != "coordinate") {
                log.info('[samtools sort] Unknown sort - defaulting to coordinate.')
            }
            extra_command += " --write-index"
        }
        extra_command += " --threads " + task.cpus
        extra_command += " -o " + prefix + ".mapped.bam##idx##" + prefix + ".mapped.bam.bai"
        extra_command += " " + prefix + ".zipped.bam"
    }

    """
    # The real path to the BWA index prefix`
    BWA_INDEX_PREFIX=`find -L ./ -name "*.amb" | sed 's/.amb//'`

    samtools fastq ${samtools_fastq_args} ${unmapped_bam} \\
        | bwa-mem3 mem ${bwa_args} -t ${task.cpus} -p -K 150000000 -Y \$BWA_INDEX_PREFIX - \\
        | fgumi zipper \\
            --input - \\
            --unmapped ${unmapped_bam} \\
            --reference ${fasta} \\
            --compression-level ${zipper_compression} \\
            -t ${task.cpus} \\
            --skip-pa-tags \\
            --output ${zipper_output} \\
            ${fgumi_zipper_args}

    ${extra_command}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem3: \$(bwa-mem3 version | sed -nE '1 s/^([0-9]+(\\.[0-9]+)+).*/\\1/p')
        fgumi: \$(fgumi --version 2>&1 | sed 's/^fgumi //')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def index_command = sort_type != "template-coordinate" ? "touch ${prefix}.mapped.bam.bai" : ""
    """
    touch ${prefix}.mapped.bam
    ${index_command}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem3: \$(bwa-mem3 version | sed -nE '1 s/^([0-9]+(\\.[0-9]+)+).*/\\1/p')
        fgumi: \$(fgumi --version 2>&1 | sed 's/^fgumi //')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
