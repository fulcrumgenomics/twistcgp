/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTP } from '../modules/nf-core/fastp/main'
include { FASTQC } from '../modules/nf-core/fastqc/main'
include { FGBIO_FASTQTOBAM } from '../modules/nf-core/fgbio/fastqtobam/main'
include { MULTIQC } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap } from 'plugin/nf-schema'
include { paramsSummaryMultiqc } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_twistcgp_pipeline'

include { ALIGNBAM } from '../modules/local/alignbam'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TWISTCGP {
    take:
    ch_samplesheet // channel: samplesheet read in from --input
    adapters_fasta // optional path to adapter sequences
    ch_bwa // channel: val(reference meta), path(bwamem2 index directory)
    ch_dict // channel: val(reference meta), path(reference .dict file)
    ch_fasta // channel: val(reference meta), path(reference FASTA file)
    ch_fasta_fai // channle: val(reference meat), path(reference .fai file)

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    //
    // MODULE: Run FastQC
    //
    FASTQC(ch_samplesheet)

    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect { it[1] })
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: Run fastp
    //
    // Always output filtered and discarded read FASTQs, never output a merged fastq
    FASTP(ch_samplesheet, adapters_fasta, false, true, false)
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect { it[1] })
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    //
    // MODULE: Run fastqtobam
    //
    FGBIO_FASTQTOBAM(FASTP.out.reads)
    ch_versions = ch_versions.mix(FGBIO_FASTQTOBAM.out.versions.first())

    //
    // MODULE: Run ALIGNBAM
    //
    ALIGNBAM(FGBIO_FASTQTOBAM.out.bam, ch_fasta, ch_fasta_fai, ch_dict, ch_bwa, "coordinate")

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'twistcgp_software_' + 'mqc_' + 'versions.yml',
            sort: true,
            newLine: true,
        )
        .set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config = Channel.fromPath(
        "${projectDir}/assets/multiqc_config.yml",
        checkIfExists: true
    )
    ch_multiqc_custom_config = params.multiqc_config
        ? Channel.fromPath(params.multiqc_config, checkIfExists: true)
        : Channel.empty()
    ch_multiqc_logo = params.multiqc_logo
        ? Channel.fromPath(params.multiqc_logo, checkIfExists: true)
        : Channel.empty()

    summary_params = paramsSummaryMap(
        workflow,
        parameters_schema: "nextflow_schema.json"
    )
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
    )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        [],
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions = ch_versions // channel: [ path(versions.yml) ]
}
