/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { ALIGNBAM } from '../modules/local/alignbam'
include { CIVICPY } from '../modules/local/civicpy/main'
include { FASTP } from '../modules/nf-core/fastp/main'
include { FASTQC } from '../modules/nf-core/fastqc/main'
include { FGBIO_FASTQTOBAM } from '../modules/nf-core/fgbio/fastqtobam/main'
include { GATK4_MUTECT2 } from '../modules/nf-core/gatk4/mutect2/main'
include { GIT_CLONEMSISENSOR2MODEL } from '../modules/local/git/clonemsisensor2model/main'
include { MSISENSOR2_MSI } from '../modules/nf-core/msisensor2/msi/main'
include { MSISENSORPRO_PRO } from '../modules/nf-core/msisensorpro/pro/main'
include { MULTIQC } from '../modules/nf-core/multiqc/main'
include { PERBASE } from '../modules/nf-core/perbase/main'
include { PICARD_MARKDUPLICATES } from '../modules/nf-core/picard/markduplicates'
include { PICARD_COLLECTMULTIPLEMETRICS } from '../modules/nf-core/picard/collectmultiplemetrics'
include { PICARD_COLLECTHSMETRICS } from '../modules/nf-core/picard/collecthsmetrics/main'
include { PICARD_INTERVALLISTTOBED } from '../modules/local/picard/intervallisttobed'
include { paramsSummaryMap } from 'plugin/nf-schema'
include { paramsSummaryMultiqc } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_twistcgp_pipeline'
include { CNVKIT_BATCH } from '../modules/nf-core/cnvkit/batch/main'
include { VCF_ANNOTATE } from '../subworkflows/local/vcf_annotate/main'
include { TMB } from '../modules/local/tmb'

include { PICARD_INTERVALLISTTOBED as BAITS_TO_BED } from '../modules/local/picard/intervallisttobed'
include { PICARD_INTERVALLISTTOBED as TARGETS_TO_BED } from '../modules/local/picard/intervallisttobed'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TWISTCGP {
    take:
    ch_samplesheet // channel: samplesheet read in from --input
    baits // channel: tuple of meta and baits region file read in from --baits
    targets // channel: tuple of meta and targets region file read in from --targets
    use_msi_pro // boolean indicating if MSIsensor-pro can be run
    msi_sensor2_model_name // name of desired model directory in https://github.com/niu-lab/msisensor2.git
    adapters_fasta // optional path to adapter sequences
    pon_cnn // optional path to panel of normal reference CNN file for use with CNVkit
    ch_bwa // channel: val(reference meta), path(bwamem2 index directory)
    ch_dict // channel: val(reference meta), path(reference .dict file)
    ch_fasta // channel: val(reference meta), path(reference FASTA file)
    ch_fasta_fai // channel: val(reference meta), path(reference .fai file)
    ch_fasta_gzi // channel: val(reference meta), path(reference .gzi file)
    ch_pop_germline_resource // channel [optional]: val(reference_meta), path(germline_resource VCF)
    ch_pop_germline_resource_tbi /// channel [optional]: val(reference_meta), path(germline_resource VCF index)
    ch_pon_vcf // channel [optional]: val(reference_meta), path(panel_of_normals VCF)
    ch_pon_tbi // channel [optional]: val(reference_meta), path(panel_of_normals VCF index)
    snpeff_genome_info // channel: [ val(meta), val(genome_info) ]
    ensemblvep_info // channel: [ val(meta), val(genome_version), val(vep_species), val(cache_version) ]
    ch_snpeff_cache // channel [optional]: path(snpeff_cache)
    tmb_mutect2_config // path(tmb_mutect2_config)
    tmb_vep_config /// path(tmb_vep_config)
    ch_vep_cache // channel [optional]: path(vep_cache)
    vep_extra_files // channel [optional]: [path(cosmic_vcf)]
    ch_msi_scan // channel: tuple val(meta), path(msisensor_scan)

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
    ch_versions = ch_versions.mix(ALIGNBAM.out.versions.first())

    //
    // MODULE: PICARD_MARKDUPLICATES
    //
    PICARD_MARKDUPLICATES(ALIGNBAM.out.bam, ch_fasta, ch_fasta_fai)
    ch_bam_and_index = PICARD_MARKDUPLICATES.out.bam.join(PICARD_MARKDUPLICATES.out.bai)
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_MARKDUPLICATES.out.metrics.collect { it[1] })
    ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions.first())

    //
    // MODULE: GATK4/MUTECT2
    //
    // GATK4_MUTECT2 expects just the path for each of the VCF files, no meta
    ch_bams_and_targets = PICARD_MARKDUPLICATES.out.bam
        .join(PICARD_MARKDUPLICATES.out.bai)
        .map { meta, bam, bai -> tuple(meta, bam, bai, targets[1]) }
    GATK4_MUTECT2(
        ch_bams_and_targets,
        ch_fasta,
        ch_fasta_fai,
        ch_fasta_gzi,
        ch_dict,
        ch_pop_germline_resource.map { _meta, vcf -> vcf },
        ch_pop_germline_resource_tbi.map { _meta, tbi -> tbi },
        ch_pon_vcf.map { _meta, vcf -> vcf },
        ch_pon_tbi.map { _meta, tbi -> tbi },
    )
    ch_versions = ch_versions.mix(GATK4_MUTECT2.out.versions.first())

    //
    // SUB-WORKFLOW: VCF_ANNOTATE
    //
    VCF_ANNOTATE(
        GATK4_MUTECT2.out.vcf,
        ch_fasta,
        snpeff_genome_info,
        ensemblvep_info,
        ch_snpeff_cache,
        ch_vep_cache,
        vep_extra_files,
    )
    ch_versions = ch_versions.mix(VCF_ANNOTATE.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix(VCF_ANNOTATE.out.reports)

    //
    // MODULE: TMB
    //
    //
    TMB(VCF_ANNOTATE.out.vcf_ann, targets, tmb_vep_config, tmb_mutect2_config)
    ch_versions = ch_versions.mix(TMB.out.versions.first())

    //
    // MODULE: CIVICPY
    //
    CIVICPY(VCF_ANNOTATE.out.vcf_ann, params.annotation_genome_version)

    //
    // CNVKIT_BATCH
    //
    // Currently the pipeline does not support matched tumor-normal analysis, so an empty
    //   list is supplied for the normal BAM.
    baits_are_bed = baits[1].getExtension() == "bed"
    if (!baits_are_bed) {
        BAITS_TO_BED(baits)
    }
    ch_baits_bed = baits_are_bed ? baits : BAITS_TO_BED.out.bed.collect()
    ch_cnv_bam_pair = PICARD_MARKDUPLICATES.out.bam.map { meta, bam -> tuple(meta, bam, []) }
    CNVKIT_BATCH(
        ch_cnv_bam_pair,
        ch_fasta,
        ch_fasta_fai,
        ch_baits_bed,
        tuple([], pon_cnn),
        false,
    )
    ch_versions = ch_versions.mix(CNVKIT_BATCH.out.versions.first())

    //
    // MODULE: MSISENSOR2_MSI or MSISENSORPRO_PRO
    //
    // MSIsensor-pro is free for non-profit use but a license is required for commercial use
    // https://github.com/xjtu-omics/msisensor-pro/blob/master/docs/2_License.md
    if (use_msi_pro) {
        MSISENSORPRO_PRO(
            ch_bam_and_index,
            ch_msi_scan,
            [[:], []],
            [[:], []],
        )
        ch_versions = ch_versions.mix(MSISENSORPRO_PRO.out.versions.first())
    }
    else {
        targets_are_bed = targets[1].getExtension() == "bed"
        if (!targets_are_bed) {
            TARGETS_TO_BED(targets)
        }
        targets_bed = targets_are_bed ? targets : TARGETS_TO_BED.out.bed.collect()
        // Currently the pipeline does not support matched tumor-normal analysis, so an empty
        //   list is supplied for the normal BAM.
        ch_bam_and_target_bed = ch_bam_and_index.map { meta, bam, bai -> tuple(meta, bam, bai, [], [], targets_bed[1]) }
        GIT_CLONEMSISENSOR2MODEL(msi_sensor2_model_name)
        ch_versions = ch_versions.mix(GIT_CLONEMSISENSOR2MODEL.out.versions.first())
        MSISENSOR2_MSI(
            ch_bam_and_target_bed,
            ch_msi_scan.collect().map { it -> it[1] },
            GIT_CLONEMSISENSOR2MODEL.out.model.collect(),
        )
        ch_versions = ch_versions.mix(MSISENSOR2_MSI.out.versions.first())
    }


    //
    // MODULE: PICARD_COLLECTMULTIPLEMETRICS
    //
    PICARD_COLLECTMULTIPLEMETRICS(ALIGNBAM.out.bam_bai, ch_fasta, ch_fasta_fai)
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_COLLECTMULTIPLEMETRICS.out.metrics.collect { it[1] })
    ch_versions = ch_versions.mix(PICARD_COLLECTMULTIPLEMETRICS.out.versions.first())

    //
    // MODULE: PICARD_COLLECTHSMETRICS
    //
    ch_bam_and_regions = ch_bam_and_index.map { meta, bam, bai -> tuple(meta, bam, bai, baits[1], targets[1]) }
    PICARD_COLLECTHSMETRICS(ch_bam_and_regions, ch_fasta, ch_fasta_fai, ch_fasta_gzi, ch_dict)
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_COLLECTHSMETRICS.out.metrics.collect { it[1] })
    ch_versions = ch_versions.mix(PICARD_COLLECTHSMETRICS.out.versions.first())

    //
    // MODULE: PERBASE
    //
    PERBASE(ALIGNBAM.out.bam_bai, ch_fasta.join(ch_fasta_fai).first())
    ch_versions = ch_versions.mix(PERBASE.out.versions.first())

    //
    // Collate and save software versions
    //
    ch_collated_versions = softwareVersionsToYAML(ch_versions).collectFile(
        storeDir: "${params.outdir}/pipeline_info",
        name: 'twistcgp_software_mqc_versions.yml',
        sort: true,
        newLine: true,
    )

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
