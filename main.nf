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
    ch_pop_germline_resource_tbi = params.population_germline_resource_tbi ? Channel.fromPath(params.population_germline_resource_tbi) : []


    ch_pon_vcf = Channel.value(
        tuple([id: 'pon_vcf'], params.pon_vcf ? file(params.pon_vcf) : [])
    )
    ch_pon_tbi = params.pon_tbi ? Channel.fromPath(params.pon_tbi) : []


    // VCF Annotation Parameters (SnpEff + VEP)
    snpeff_genome_info = Channel.value([[id: "${params.annotation_genome_version}.${params.snpeff_db}"], "${params.annotation_genome_version}.${params.snpeff_db}"])
    snpeff_cache = params.snpeff_cache ? file(params.snpeff_cache) : []

    tmb_mutect2_config = Channel.fromPath(params.tmb_mutect2_config).collect()
    tmb_vep_config = Channel.fromPath(params.tmb_vep_config).collect()

    ensemblvep_info = Channel.value(
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
    ch_cosmic_tbi = params.cosmic_tbi ? Channel.fromPath(params.cosmic_tbi) : []

    ch_gnomad_vcf = Channel.value(
        tuple([id: 'gnomad_vcf'], params.gnomad_vcf ? file(params.gnomad_vcf) : [])
    )
    ch_gnomad_tbi = params.gnomad_tbi ? Channel.fromPath(params.gnomad_tbi) : []


    FULCRUMGENOMICS_TWISTCGP(
        PIPELINE_INITIALISATION.out.samplesheet,
        baits,
        targets,
        adapters_fasta,
        pon_cnn,
        ch_pop_germline_resource,
        ch_pop_germline_resource_tbi,
        ch_pon_vcf,
        ch_pon_tbi,
        snpeff_genome_info,
        ensemblvep_info,
        snpeff_cache,
        tmb_mutect2_config,
        tmb_vep_config,
        ensemblvep_cache,
        ch_cosmic_vcf,
        ch_cosmic_tbi,
        ch_gnomad_vcf,
        ch_gnomad_tbi,
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
    ch_pop_germline_resource_tbi // optional path(germline_resource TBI)
    ch_pon_vcf // optional val(reference meta), path(panel_of_normals VCF)
    ch_pon_tbi // optional path(panel_of_normals TBI)
    snpeff_genome_info // channel: tuple val(meta), val(snpeff_db)
    ensemblvep_info // channel: [ val(meta), val(genome_version), val(vep_species), val(cache_version) ]
    snpeff_cache // channel: path(snpeff_cache)
    tmb_mutect2_config // required path to variant calling config file
    tmb_vep_config // required path to variant annotation config file
    ensemblvep_cache // channel: path(ensemblvep_cache)
    ch_cosmic_vcf // optional val(reference meta), path(cosmic VCF)
    ch_cosmic_tbi // optional path(COSMIC TBI)
    ch_gnomad_vcf // optional val(reference meta), path(gnomAD VCF)
    ch_gnomad_tbi // optional path(gnomAD TBI)

    main:
    // Initialize fasta file with meta map:
    fasta = params.fasta ? Channel.fromPath(params.fasta).map { it -> [[id: it.baseName], it] }.collect() : Channel.empty()

    //
    // WORKFLOW: build indexes if needed
    //

    PREPARE_GENOME(fasta, params.use_msisensor_pro_licensed)
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
    ch_msi_scan = params.msisensor_scan
        ? Channel.fromPath(params.msisensor_scan).map { it -> [[id: 'scan'], it] }.collect()
        : PREPARE_GENOME.out.msi_scan

    // VEP extra files
    // the files provided here should match the file in ext.args in modules.config
    vep_extra_files = []

    if (params.cosmic_vcf && params.cosmic_tbi) {
        vep_extra_files << [params.cosmic_vcf, params.cosmic_tbi]
    }

    if (params.gnomad_vcf && params.gnomad_tbi) {
        vep_extra_files << [params.gnomad_vcf, params.gnomad_tbi]
    }

    // WORKFLOW: Run pipeline
    //
    TWISTCGP(
        ch_samplesheet,
        baits,
        targets,
        params.use_msisensor_pro_licensed,
        params.msisensor2_model_name,
        adapters_fasta,
        pon_cnn,
        bwa,
        dict,
        fasta,
        fasta_fai,
        fasta_gzi,
        ch_pop_germline_resource,
        ch_pop_germline_resource_tbi,
        ch_pon_vcf,
        ch_pon_tbi,
        snpeff_genome_info,
        ensemblvep_info,
        ch_snpeff_cache,
        tmb_mutect2_config,
        tmb_vep_config,
        ch_vep_cache,
        vep_extra_files,
        ch_msi_scan,
    )

    emit:
    multiqc_report = TWISTCGP.out.multiqc_report // channel: /path/to/multiqc_report.html
}
