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
    tuple val("${task.process}"), val('bwamem3'), eval("bwa-mem3 version | sed -nE '1 s/^([0-9]+(\\.[0-9]+)+).*/\\1/p'"), topic: versions, emit: versions_bwamem3
    tuple val("${task.process}"), val('fgumi'), eval("fgumi --version | sed 's/^fgumi //'"), topic: versions, emit: versions_fgumi
    tuple val("${task.process}"), val('samtools'), eval("samtools --version | sed -n '1s/^samtools //p'"), topic: versions, emit: versions_samtools

    when:
    task.ext.when == null || task.ext.when

    script:
    def fgumi_fastq_args = task.ext.fgumi_fastq_args ?: ''
    def fgumi_sort_args = task.ext.fgumi_sort_args ?: ''
    def bwa_args = task.ext.bwa_args ?: ''
    def fgumi_zipper_args = task.ext.fgumi_zipper_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def sorting = sort_type != "none"

    if (sorting && sort_type != "coordinate" && sort_type != "template-coordinate") {
        log.info('[fgumi sort] Unknown sort - defaulting to coordinate.')
    }

    // Streamed into fgumi sort, which recompresses, so write uncompressed BGZF to stdout.
    def zipper_output = sorting ? "-" : "${prefix}.mapped.bam"
    def zipper_compression = sorting ? 0 : 1

    def sort_command = ''
    if (sorting) {
        def sort_order = sort_type == "template-coordinate" ? 'template-coordinate' : 'coordinate'
        // fgumi sort only accepts --write-index for a coordinate sort.
        def index_arg = sort_order == 'coordinate' ? '--write-index' : ''
        sort_command = "| fgumi sort --input - --output ${prefix}.mapped.bam --order ${sort_order} ${index_arg} --threads ${task.cpus} ${fgumi_sort_args}"
    }

    """
    # The real path to the BWA index prefix
    BWA_INDEX_PREFIX=`find -L ./ -name "*.amb" | sed 's/.amb//'`

    # fgumi fastq's default --bwa-chunk-size (150M) sizes its output buffer to match bwa mem -K below; keep the two in sync.
    fgumi fastq --input ${unmapped_bam} --threads ${task.cpus} ${fgumi_fastq_args} \\
        | bwa-mem3 mem ${bwa_args} -t ${task.cpus} -p -K 150000000 -Y \$BWA_INDEX_PREFIX - \\
        | fgumi zipper \\
            --input - \\
            --unmapped ${unmapped_bam} \\
            --reference ${fasta} \\
            --compression-level ${zipper_compression} \\
            --threads ${task.cpus} \\
            --output ${zipper_output} \\
            ${fgumi_zipper_args} \\
        ${sort_command}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def index_command = sort_type != "template-coordinate" ? "touch ${prefix}.mapped.bam.bai" : ""
    """
    touch ${prefix}.mapped.bam
    ${index_command}
    """
}
