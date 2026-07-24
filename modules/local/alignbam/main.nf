process ALIGNBAM {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/bwa-mem3_fgbio_samtools_findutils_pruned:1006c4a7ef624968':
        'community.wave.seqera.io/library/bwa-mem3_fgbio_samtools_findutils_pruned:9e2621cba043722e' }"

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
    def fgbio_args = task.ext.fgbio_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def fgbio_mem_gb = 4
    def extra_command = ""
    if (!task.memory) {
        log.info('[fgbio ZipperBams] Available memory not known - defaulting to 4GB. Specify process memory requirements to change this.')
    }
    else if (fgbio_mem_gb > task.memory.giga) {
        if (task.memory.giga < 2) {
            fgbio_mem_gb = 1
        }
        else {
            fgbio_mem_gb = task.memory.giga - 1
        }
    }

    if (sort_type == "none") {
        fgbio_zipper_bams_output = prefix + ".mapped.bam"
        fgbio_zipper_bams_compression = 1
    }
    else {
        // Write ZipperBams output to an intermediate file and sort that file, rather than
        // piping fgbio's output through /dev/stdout. Writing to the literal /dev/stdout path
        // is unreliable under Singularity (it is a /proc/self/fd symlink that does not resolve
        // to the downstream pipe), so a piped `samtools sort -` receives a broken stream and
        // fails with "Exec format error". Docker resolves /dev/stdout correctly, so this only
        // manifests under Singularity/Apptainer. Sorting a real file works under both.
        fgbio_zipper_bams_output = prefix + ".zipped.bam"
        fgbio_zipper_bams_compression = 1
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
        | fgbio -Xmx${fgbio_mem_gb}g \\
            --compression ${fgbio_zipper_bams_compression} \\
            --async-io=true \\
            ZipperBams \\
            --unmapped ${unmapped_bam} \\
            --ref ${fasta} \\
            --output ${fgbio_zipper_bams_output} \\
            ${fgbio_args}

    ${extra_command}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem3: \$(bwa-mem3 version | sed -nE '1 s/^([0-9]+(\\.[0-9]+)+).*/\\1/p')
        fgbio: \$( echo \$(fgbio --version 2>&1 | tr -d '[:cntrl:]' ) | sed -e 's/^.*Version: //;s/\\[.*\$//')
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
        fgbio: \$( echo \$(fgbio --version 2>&1 | tr -d '[:cntrl:]' ) | sed -e 's/^.*Version: //;s/\\[.*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
