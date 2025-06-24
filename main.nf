#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    fulcrumgenomics/twistcgp
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/fulcrumgenomics/twistcgp
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { TWISTCGP } from './workflows/twistcgp'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_twistcgp_pipeline'
include { PIPELINE_COMPLETION } from './subworkflows/local/utils_nfcore_twistcgp_pipeline'
include { PREPARE_GENOME } from './subworkflows/local/prepare_genome'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION(
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input,
    )

    //
    // WORKFLOW: Run main workflow
    //
    adapters_fasta = params.adapters_fasta ? file(params.adapters_fasta) : []
    pon_cnn = params.pon_cnn ? file(params.pon_cnn) : []
    baits = tuple([id:"baits"], file(params.baits))
    targets = tuple([id:"targets"], file(params.targets))
    germline_resource = params.germline_resource ? params.germline_resource : []
    germline_resource_tbi = params.germline_resource_tbi ? params.germline_resource_tbi : []
    pon = params.pon ? params.pon : []
    pon_tbi = params.pon_tbi ? params.pon_tbi : []
    FULCRUMGENOMICS_TWISTCGP(
        PIPELINE_INITIALISATION.out.samplesheet,
        baits,
        targets,
        adapters_fasta,
        pon_cnn
        germline_resource,
        germline_resource_tbi,
        pon,
        pon_tbi,
    )

    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION(
        params.outdir,
        params.monochrome_logs,
        FULCRUMGENOMICS_TWISTCGP.out.multiqc_report,
    )
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow FULCRUMGENOMICS_TWISTCGP {
    take:
    ch_samplesheet // channel: samplesheet read in from --input
    baits // tuple of meta and baits regions file read in from --baits
    targets //tuple of meta and targets regions file read in from --targets
    adapters_fasta // optional path to adapter sequences
    pon_cnn // optional path to panel of normal reference CNN file for use with CNVkit
    germline_resource //optional path to germline_resource VCF
    germline_resource_tbi //optional path to germline_resource index
    pon //optional path to panel_of_normals VCF
    pon_tbi //optional path to panel_of_normals VCF index

    main:
    // Initialize fasta file with meta map:
    fasta = params.fasta ? Channel.fromPath(params.fasta).map { it -> [[id: it.baseName], it] }.collect() : Channel.empty()

    //
    // WORKFLOW: build indexes if needed
    //
    PREPARE_GENOME(fasta)

    // Gather built indices or get them from the params
    // Built from the fasta file:
    dict = params.dict
        ? Channel.fromPath(params.dict).map { it -> [[id: 'dict'], it] }.collect()
        : PREPARE_GENOME.out.dict

    fasta_fai = params.fasta_fai
        ? Channel.fromPath(params.fasta_fai).map { it -> [[id: 'fai'], it] }.collect()
        : PREPARE_GENOME.out.fasta_fai
    fasta_gzi = params.fasta_gzi
        ? Channel.fromPath(params.fasta_gzi).map { it -> [[id: 'gzi'], it] }.collect()
        : { file(params.fasta).getExtension() == 'gz' ? PREPARE_GENOME.out.fasta_gzi : Channel.value([[id: "gzi"], []]) }
    bwa = params.bwa
        ? Channel.fromPath(params.bwa).map { it -> [[id: 'bwa'], it] }.collect()
        : PREPARE_GENOME.out.bwa

    // Grab inputs for GATK4/MUTECT2 from params
    // optional args that are not provided are instantiated as a value channel with an empty list
    germline_resource = params.germline_resource
    ? Channel.fromPath(params.germline_resource)
    : Channel.value([])

    germline_resource_tbi = params.germline_resource_tbi
    ? Channel.fromPath(params.germline_resource_tbi)
    : Channel.value([])

    pon = params.pon
    ? Channel.fromPath(params.pon)
    : Channel.value([])

    pon_tbi = params.pon_tbi
    ? Channel.fromPath(params.pon_tbi)
    : Channel.value([])

    //
    // WORKFLOW: Run pipeline
    //
    TWISTCGP(
        ch_samplesheet,
        baits,
        targets,
        adapters_fasta,
        pon_cnn,
        bwa,
        dict,
        fasta,
        fasta_fai,
        fasta_gzi,
        germline_resource,
        germline_resource_tbi,
        pon,
        pon_tbi,
    )

    emit:
    multiqc_report = TWISTCGP.out.multiqc_report // channel: /path/to/multiqc_report.html
}
