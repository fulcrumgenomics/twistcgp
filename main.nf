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
include { PREPARE_INDICES } from './subworkflows/local/prepare_indices'
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
        params.help,
        params.help_full,
        params.show_hidden,
    )

    //
    // WORKFLOW: Run main workflow
    //
    adapters_fasta = params.adapters_fasta ? file(params.adapters_fasta) : []
    pon_cnn = params.pon_cnn ? file(params.pon_cnn) : []
    baits = tuple([id: "baits"], file(params.baits))
    targets = tuple([id: "targets"], file(params.targets))

    ch_pop_germline_resource = channel.value(
        tuple([id: 'population_germline_resource'], params.population_germline_vcf ? file(params.population_germline_vcf) : [])
    )

    ch_pon_vcf = channel.value(
        tuple([id: 'pon_vcf'], params.pon_vcf ? file(params.pon_vcf) : [])
    )

    // VCF Annotation Parameters (SnpEff + VEP)
    snpeff_genome_info = channel.value([[id: "${params.annotation_genome_version}.${params.snpeff_db}"], "${params.annotation_genome_version}.${params.snpeff_db}"])
    snpeff_cache = params.snpeff_cache ? file(params.snpeff_cache) : []

    tmb_mutect2_config = channel.fromPath(params.tmb_mutect2_config).collect()
    tmb_vep_config = channel.fromPath(params.tmb_vep_config).collect()

    ensemblvep_info = channel.value(
        tuple(
            [id: "${params.ensemblvep_cache_version}_${params.annotation_genome_version}"],
            params.annotation_genome_version,
            params.ensemblvep_species,
            params.ensemblvep_cache_version,
        )
    )
    ensemblvep_cache = params.ensemblvep_cache ? file(params.ensemblvep_cache) : []

    ch_cosmic_vcf = channel.value(
        tuple([id: 'cosmic_vcf'], params.cosmic_vcf ? file(params.cosmic_vcf) : [])
    )

    FULCRUMGENOMICS_TWISTCGP(
        PIPELINE_INITIALISATION.out.samplesheet,
        baits,
        targets,
        adapters_fasta,
        pon_cnn,
        ch_pop_germline_resource,
        ch_pon_vcf,
        snpeff_genome_info,
        ensemblvep_info,
        snpeff_cache,
        tmb_mutect2_config,
        tmb_vep_config,
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
    ch_pon_vcf // optional val(reference meta), path(panel_of_normals VCF)
    snpeff_genome_info // channel: tuple val(meta), val(snpeff_db)
    ensemblvep_info // channel: [ val(meta), val(genome_version), val(vep_species), val(cache_version) ]
    snpeff_cache // channel: path(snpeff_cache)
    tmb_mutect2_config // required path to variant calling config file
    tmb_vep_config // required path to variant annotation config file
    ensemblvep_cache // channel: path(ensemblvep_cache)
    ch_cosmic_vcf // optional val(reference meta), path(cosmic VCF)

    main:
    // Initialize fasta file with meta map:
    fasta = params.fasta ? channel.fromPath(params.fasta).map { path -> [[id: path.baseName], path] }.collect() : channel.empty()

    //
    // WORKFLOW: build indexes if needed
    //

    PREPARE_GENOME(fasta, params.use_msisensor_pro_licensed)
    PREPARE_INDICES(ch_pop_germline_resource, ch_pon_vcf, ch_cosmic_vcf)
    PREPARE_ANNOTATION_DB(
        ensemblvep_info,
        snpeff_genome_info,
    )

    // Collect tool versions from the reference-preparation subworkflows so they reach the
    // software-versions report (they emit `versions` but were previously never collated).
    ch_prepare_versions = PREPARE_GENOME.out.versions
        .mix(PREPARE_INDICES.out.versions)
        .mix(PREPARE_ANNOTATION_DB.out.versions)

    // Gather built indices or get them from the params
    // Built from the fasta file:
    dict = params.dict
        ? channel.fromPath(params.dict).map { path -> [[id: 'dict'], path] }.collect()
        : PREPARE_GENOME.out.dict
    fasta_fai = params.fasta_fai
        ? channel.fromPath(params.fasta_fai).map { path -> [[id: 'fai'], path] }.collect()
        : PREPARE_GENOME.out.fasta_fai
    fasta_gzi = params.fasta_gzi
        ? channel.fromPath(params.fasta_gzi).map { path -> [[id: 'gzi'], path] }.collect()
        : (file(params.fasta).getExtension() == 'gz' ? PREPARE_GENOME.out.fasta_gzi : channel.value([[id: "gzi"], []]))
    bwa = params.bwa
        ? channel.fromPath(params.bwa).map { path -> [[id: 'bwa'], path] }.collect()
        : PREPARE_GENOME.out.bwa
    ch_snpeff_cache = params.snpeff_cache
        ? channel.fromPath(params.snpeff_cache).map { path -> [[id: 'snpeff_cache'], path] }.collect()
        : PREPARE_ANNOTATION_DB.out.snpeff_cache
    ch_vep_cache = params.ensemblvep_cache
        ? channel.fromPath(params.ensemblvep_cache).map { path -> [[id: 'vep_cache'], path] }.collect()
        : PREPARE_ANNOTATION_DB.out.ensemblvep_cache
    ch_msi2_scan = params.msisensor2_scan
        ? channel.fromPath(params.msisensor2_scan).map { path -> [[id: 'msi2_scan'], path] }.collect()
        : channel.value([[id: 'msi2_scan'], []])

    ch_msi_pro_sites = params.msisensor_pro_sites
        ? channel.fromPath(params.msisensor_pro_sites).map { path -> [[id: 'msi_pro_sites'], path] }.collect()
        : (params.use_msisensor_pro_licensed ? PREPARE_GENOME.out.msi_scan : channel.value([[id: 'msi_pro_sites'], []]))

    //GATK Mutect2 resources
    ch_pop_germline_resource_tbi = params.population_germline_tbi
        ? channel.fromPath(params.population_germline_tbi).map { path -> [[id: 'population_germline_resource_tbi'], path] }.collect()
        : (params.population_germline_vcf ? PREPARE_INDICES.out.ch_germline_resource_tbi : channel.value([[id: 'population_germline_resource_tbi'], []]))

    ch_pon_tbi = params.pon_tbi
        ? channel.fromPath(params.pon_tbi).map { path -> [[id: 'pon_tbi'], path] }.collect()
        : (params.pon_vcf ? PREPARE_INDICES.out.ch_pon_tbi : channel.value([[id: 'pon_tbi'], []]))

    // VEP extra files
    ch_cosmic_tbi = params.cosmic_tbi
        ? channel.fromPath(params.cosmic_tbi).map { path -> [[id: 'cosmic_tbi'], path] }.collect()
        : (params.cosmic_vcf ? PREPARE_INDICES.out.ch_cosmic_tbi : channel.value([[id: 'cosmic_tbi'], []]))

    vep_extra_files = channel.empty()
    // Check for a COSMIC VCF; its VCF and TBI both get passed to VEP
    if (params.cosmic_vcf) {
        vep_extra_files = vep_extra_files
            .mix(ch_cosmic_vcf)
            .mix(ch_cosmic_tbi)
    }

    vep_extra_files_no_meta = params.cosmic_vcf
        ? vep_extra_files.map { _m, f -> f }.collect()
        : channel.value([])

    // Staged COSMIC basename for VEP's --custom.
    vep_custom_name = params.cosmic_vcf ? file(params.cosmic_vcf).name : null

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
        vep_extra_files_no_meta,
        vep_custom_name,
        ch_msi2_scan,
        ch_msi_pro_sites,
        params.skip_tmb,
        params.skip_civicpy,
        params.skip_cnv,
        params.skip_msi,
        params.annotation_genome_version,
        params.outdir,
        params.multiqc_config,
        params.multiqc_logo,
        ch_prepare_versions,
    )

    emit:
    multiqc_report = TWISTCGP.out.multiqc_report // channel: /path/to/multiqc_report.html
}
