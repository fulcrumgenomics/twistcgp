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
include { PREPARE_INDICES } from './subworkflows/local/prepare_indices'
include { PREPARE_ANNOTATION_DB } from './subworkflows/local/prepare_annotation_db'

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
    baits = tuple([id: "baits"], file(params.baits))
    targets = tuple([id: "targets"], file(params.targets))

    ch_pop_germline_resource = Channel.value(
        tuple([id: 'population_germline_resource'], params.population_germline_vcf ? file(params.population_germline_vcf) : [])
    )

    germline_resource_tbi = params.population_germline_tbi ? file(params.population_germline_tbi) : []

    ch_pon_vcf = Channel.value(
        tuple([id: 'pon_vcf'], params.pon_vcf ? file(params.pon_vcf) : [])
    )

    pon_tbi = params.pon_tbi ? file(params.pon_tbi) : []

    // VCF Annotation Parameters (SnpEff + VEP)
    snpeff_genome_info = Channel.value([[id: "${params.annotation_genome_version}.${params.snpeff_db}"], "${params.annotation_genome_version}.${params.snpeff_db}"])
    snpeff_cache = params.snpeff_cache ? file(params.snpeff_cache) : []

    tmb_mutect2_config = file(params.tmb_mutect2_config)
    tmb_snpeff_config = file(params.tmb_snpeff_config)

    ensemblvep_info = Channel.of(
        tuple(
            [id: "${params.ensemblvep_cache_version}_${params.annotation_genome_version}"],
            params.annotation_genome_version,
            params.ensemblvep_species,
            params.ensemblvep_cache_version,
        )
    )
    ensemblvep_cache = params.ensemblvep_cache ? file(params.ensemblvep_cache) : []

    ch_cosmic_vcf = Channel.value(
        tuple([id: 'cosmic_vcf'], params.cosmic_vcf ? file(params.cosmic_vcf) : [])
    )
    FULCRUMGENOMICS_TWISTCGP(
        PIPELINE_INITIALISATION.out.samplesheet,
        baits,
        targets,
        adapters_fasta,
        pon_cnn,
        ch_pop_germline_resource,
        germline_resource_tbi,
        ch_pon_vcf,
        pon_tbi,
        snpeff_genome_info,
        ensemblvep_info,
        snpeff_cache,
        tmb_mutect2_config,
        tmb_snpeff_config,
        ensemblvep_cache,
        ch_cosmic_vcf,
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
    ch_pop_germline_resource // optional val(reference meta), path(germline_resource VCF)
    germline_resource_tbi // optional path to germline_resource index
    ch_pon_vcf // optional val(reference meta), path(panel_of_normals VCF)
    pon_tbi // optional path to panel_of_normals VCF index
    snpeff_genome_info // channel: tuple val(meta), val(snpeff_db)
    ensemblvep_info // channel: [ val(meta), val(genome_version), val(vep_species), val(cache_version) ]
    snpeff_cache // channel: path(snpeff_cache)
    tmb_mutect2_config // required path to variant calling config file
    tmb_snpeff_config // required path to variant annotation config file
    ensemblvep_cache // channel: path(ensemblvep_cache)
    ch_cosmic_vcf // optional val(reference meta), path(cosmic VCF)

    main:
    // Initialize fasta file with meta map:
    fasta = params.fasta ? Channel.fromPath(params.fasta).map { it -> [[id: it.baseName], it] }.collect() : Channel.empty()

    //
    // WORKFLOW: build indexes if needed
    //

    PREPARE_GENOME(fasta)
    PREPARE_INDICES(ch_pop_germline_resource, ch_pon_vcf, ch_cosmic_vcf)
    PREPARE_ANNOTATION_DB(
        ensemblvep_info,
        snpeff_genome_info,
    )

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
    ch_snpeff_cache = params.snpeff_cache
        ? Channel.fromPath(params.snpeff_cache).map { it -> [[id: 'snpeff_cache'], it] }.collect()
        : PREPARE_ANNOTATION_DB.out.snpeff_cache
    ch_vep_cache = params.ensemblvep_cache
        ? Channel.fromPath(params.ensemblvep_cache).map { it -> [[id: 'vep_cache'], it] }.collect()
        : PREPARE_ANNOTATION_DB.out.ensemblvep_cache
    // Grab inputs for GATK4/MUTECT2 from params
    // optional args that are not provided are instantiated as a value channel with an empty list

    ch_pop_germ_tbi = params.population_germline_vcf
        ? (params.population_germline_tbi
            ? Channel.fromPath(params.population_germline_tbi).collect()
            : PREPARE_INDICES.out.ch_germline_resource_tbi)
        : Channel.value([[id: "population_germline_tbi"], []])
    ch_pon_tbi = params.pon_vcf
        ? (params.pon_tbi
            ? Channel.fromPath(params.pon_tbi).collect()
            : PREPARE_INDICES.out.ch_pon_tbi)
        : Channel.value([[id: "pon_tbi"], []])

    // VEP extra files
    vep_extra_files = []

    if (params.cosmic_vcf) {
        def cosmic_vcf_path = file(params.cosmic_vcf, checkIfExists: true)
        vep_extra_files.add(cosmic_vcf_path)
        def tbi_path = "${params.cosmic_vcf}.tbi"
        def tbi_exists = new File(tbi_path).exists()
        if (tbi_exists) {
            ch_cosmic_tbi = file(tbi_path)
            vep_extra_files.add(file(tbi_path, checkIfExists: true))
        }
        else {
            // Get the TBI file path from PREPARE_INDICES emitted channel
            ch_cosmic_tbi = PREPARE_INDICES.out.ch_cosmic_tbi.map { meta, f -> f }
            vep_extra_files.add(ch_cosmic_tbi)
        }
    }

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
        ch_pop_germline_resource,
        ch_pop_germ_tbi,
        ch_pon_vcf,
        ch_pon_tbi,
        snpeff_genome_info,
        ensemblvep_info,
        ch_snpeff_cache,
        tmb_mutect2_config,
        tmb_snpeff_config,
        ch_vep_cache,
        vep_extra_files,
    )

    emit:
    multiqc_report = TWISTCGP.out.multiqc_report // channel: /path/to/multiqc_report.html
}
