/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { ALIGNBAM } from '../modules/local/alignbam'
include { BCFTOOLS_VIEW as BCFTOOLS_VIEW_PRE_CIVIC } from '../modules/nf-core/bcftools/view/main'
include { BCFTOOLS_VIEW as BCFTOOLS_VIEW_POST_CIVIC } from '../modules/nf-core/bcftools/view/main'
include { CHELAE_TRIM } from '../modules/nf-core/chelae/trim/main'
include { CIVICPY_ANNOTATE } from '../modules/nf-core/civicpy/annotate/main'
include { CIVICPY_UPDATE_CACHE } from '../modules/local/civicpy/update_cache/main'
include { CNVKIT_BATCH } from '../modules/nf-core/cnvkit/batch/main'
include { FASTQC } from '../modules/nf-core/fastqc/main'
include { FGUMI_EXTRACT } from '../modules/nf-core/fgumi/extract/main'
include { GATK4_CALCULATECONTAMINATION } from '../modules/nf-core/gatk4/calculatecontamination/main'
include { GATK4_FILTERMUTECTCALLS } from '../modules/nf-core/gatk4/filtermutectcalls/main'
include { GATK4_GETPILEUPSUMMARIES } from '../modules/nf-core/gatk4/getpileupsummaries/main'
include { GATK4_LEARNREADORIENTATIONMODEL } from '../modules/nf-core/gatk4/learnreadorientationmodel/main'
include { GATK4_MUTECT2 } from '../modules/nf-core/gatk4/mutect2/main'
include { GIT_CLONEMSISENSOR2MODEL } from '../modules/local/git/clonemsisensor2model/main'
include { MSISENSOR2_MSI } from '../modules/nf-core/msisensor2/msi/main'
include { MSISENSORPRO_PRO } from '../modules/nf-core/msisensorpro/pro/main'
include { MULTIQC } from '../modules/nf-core/multiqc/main'
include { PERBASE } from '../modules/nf-core/perbase/main'
include { PICARD_INTERVALLISTTOBED } from '../modules/local/picard/intervallisttobed'
include { PICARD_INTERVALLISTTOBED as BAITS_TO_BED } from '../modules/local/picard/intervallisttobed'
include { PICARD_MARKDUPLICATES } from '../modules/nf-core/picard/markduplicates'
include { RIKER_MULTI } from '../modules/nf-core/riker/multi/main'
include { TMB } from '../modules/local/tmb'
include { VCF_ANNOTATE } from '../subworkflows/local/vcf_annotate/main'
include { paramsSummaryMap } from 'plugin/nf-schema'
include { paramsSummaryMultiqc } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_twistcgp_pipeline'


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
    ch_bwa // channel: val(reference meta), path(bwamem3 index directory)
    ch_dict // channel: val(reference meta), path(reference .dict file)
    ch_fasta // channel: val(reference meta), path(reference FASTA file)
    ch_fasta_fai // channel: val(reference meta), path(reference .fai file)
    ch_fasta_gzi // channel: val(reference meta), path(reference .gzi file)
    ch_pop_germline_resource // channel [optional]: val(reference_meta), path(germline_resource VCF)
    ch_pop_germline_resource_tbi // channel [optional]: val(reference_meta), path(germline_resource VCF index)
    ch_pon_vcf // channel [optional]: val(reference_meta), path(panel_of_normals VCF)
    ch_pon_tbi // channel [optional]: val(reference_meta), path(panel_of_normals VCF index)
    snpeff_genome_info // channel: [ val(meta), val(genome_info) ]
    ensemblvep_info // channel: [ val(meta), val(genome_version), val(vep_species), val(cache_version) ]
    ch_snpeff_cache // channel [optional]: path(snpeff_cache)
    tmb_mutect2_config // path(tmb_mutect2_config)
    tmb_vep_config // path(tmb_vep_config)
    ch_vep_cache // channel [optional]: path(vep_cache)
    vep_extra_files_no_meta // channel [optional]: [path(cosmic_vcf), path(cosmic_tbi), path(gnomad_vcf), path(gnomad_tbi)] (subset depending on which params are set)
    ch_msi2_scan // channel: tuple val(meta), path(msisensor2_scan) - optional scan for non-human panels
    ch_msi_pro_sites // channel: tuple val(meta), path(msisensor_pro_sites) - scan list or trained baseline for msisensor-pro
    skip_tmb // boolean: skip TMB calculation
    skip_civicpy // boolean: skip CIViCpy annotation
    skip_cnv // boolean: skip CNV analysis
    skip_msi // boolean: skip MSI analysis
    annotation_genome_version // string: genome version for annotation (e.g. GRCh38)
    outdir // string: pipeline output directory
    multiqc_config // optional path to custom MultiQC config
    multiqc_logo // optional path to custom MultiQC logo

    main:
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()
    //
    // MODULE: Run FastQC
    //
    FASTQC(ch_samplesheet)

    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect { _meta, zip -> zip })
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: Run chelae trim
    //
    CHELAE_TRIM(ch_samplesheet, adapters_fasta)
    ch_multiqc_files = ch_multiqc_files.mix(CHELAE_TRIM.out.json.collect { _meta, json -> json })

    //
    // MODULE: Convert FASTQ to an unaligned BAM
    //
    FGUMI_EXTRACT(CHELAE_TRIM.out.reads.map { meta, reads -> [meta, [reads].flatten(), meta.id] })

    //
    // MODULE: Run ALIGNBAM
    //
    ALIGNBAM(FGUMI_EXTRACT.out.bam, ch_fasta, ch_fasta_fai, ch_dict, ch_bwa, "coordinate")
    ch_versions = ch_versions.mix(ALIGNBAM.out.versions.first())

    //
    // MODULE: PICARD_MARKDUPLICATES
    //
    PICARD_MARKDUPLICATES(ALIGNBAM.out.bam, ch_fasta, ch_fasta_fai)
    ch_bam_and_index = PICARD_MARKDUPLICATES.out.bam.join(PICARD_MARKDUPLICATES.out.bai)
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_MARKDUPLICATES.out.metrics.collect { _meta, metrics -> metrics })
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
    // MODULE: GATK4/LEARNREADORIENTATIONMODEL
    // Learns strand artifact priors from f1r2 counts to filter orientation bias artifacts (e.g. FFPE deamination)
    //
    GATK4_LEARNREADORIENTATIONMODEL(
        GATK4_MUTECT2.out.f1r2.map { meta, f1r2 -> tuple(meta, [f1r2].flatten()) } // Mutect2 emits a single Path; wrap and flatten so the module always receives List<Path>
    )

    //
    // MODULE: GATK4/GETPILEUPSUMMARIES
    // Summarizes read support for known variant sites across panel to estimate cross-sample contamination
    // If no germline resource is provided, the filtered channel is empty and the process won't run
    //
    ch_germline_resource_pileup = ch_pop_germline_resource
        .filter { _meta, vcf -> vcf != [] }
        .map { _meta, vcf -> vcf }
    ch_germline_resource_pileup_tbi = ch_pop_germline_resource_tbi
        .filter { _meta, tbi -> tbi != [] }
        .map { _meta, tbi -> tbi }

    GATK4_GETPILEUPSUMMARIES(
        ch_bams_and_targets,
        ch_fasta,
        ch_fasta_fai,
        ch_dict,
        ch_germline_resource_pileup,
        ch_germline_resource_pileup_tbi,
    )

    //
    // MODULE: GATK4/CALCULATECONTAMINATION
    // Estimates cross-sample contamination from pileup summaries
    //
    ch_contamination_in = GATK4_GETPILEUPSUMMARIES.out.table
        .map { meta, table -> tuple(meta, table, []) } // no matched normal
    GATK4_CALCULATECONTAMINATION(ch_contamination_in)

    //
    // MODULE: GATK4/FILTERMUTECTCALLS
    //
    ch_mutect2_samples = GATK4_MUTECT2.out.vcf
        .join(GATK4_MUTECT2.out.tbi)
        .join(GATK4_MUTECT2.out.stats)
        .join(GATK4_LEARNREADORIENTATIONMODEL.out.artifactprior) // hard join: LROM always runs, so a missing artifact prior indicates a process failure rather than a valid skip — fail loudly rather than silently drop orientation bias filtering

    // remainder: true lets samples flow through even when CALCULATECONTAMINATION didn't run (no germline resource);
    // the final map treats both null (unmatched) and [] as "absent", so no intermediate coercion is needed.
    ch_filtermutect_in = ch_mutect2_samples
        .join(GATK4_CALCULATECONTAMINATION.out.segmentation, remainder: true)
        .join(GATK4_CALCULATECONTAMINATION.out.contamination, remainder: true)
        .map { meta, vcf, tbi, stats, artifactprior, segmentation, contamination ->
            tuple(meta, vcf, tbi, stats,
                [artifactprior],                      // orientationbias: list required for .collect() in module
                segmentation ? [segmentation] : [],   // segmentation table: list required for .collect() in module
                contamination ? [contamination] : [], // contamination table: list required for .collect() in module
                [],                                    // contamination estimate (unused)
            )
        }
    GATK4_FILTERMUTECTCALLS(
        ch_filtermutect_in,
        ch_fasta,
        ch_fasta_fai,
        ch_dict,
    )
    ch_versions = ch_versions.mix(GATK4_FILTERMUTECTCALLS.out.versions.first())

    //
    // SUB-WORKFLOW: VCF_ANNOTATE
    //
    VCF_ANNOTATE(
        GATK4_FILTERMUTECTCALLS.out.vcf,
        ch_fasta,
        snpeff_genome_info,
        ensemblvep_info,
        ch_snpeff_cache,
        ch_vep_cache,
        vep_extra_files_no_meta,
    )
    ch_versions = ch_versions.mix(VCF_ANNOTATE.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix(VCF_ANNOTATE.out.reports)

    //
    // MODULE: BCFTOOLS_VIEW_PRE_CIVIC (pre-filter before CIVICPY annotation)
    // Applies PASS/SNP/POPAF/VAF filters and targets BED to reduce variant count
    // before the expensive CIVICPY annotation step, and serves as the sole TMB
    // pre-filter when --skip_civicpy is used.
    //
    if (!skip_tmb) {
        BCFTOOLS_VIEW_PRE_CIVIC(
            VCF_ANNOTATE.out.vcf_ann,
            [], // regions (unused)
            targets[1], // targets BED file
            [], // samples (unused)
        )
        // NB: CIViCpy only sees pre-filtered PASS SNPs for TMB calculation; full VCF annotations are not required.
        if (!skip_civicpy) {
            CIVICPY_UPDATE_CACHE()
            CIVICPY_ANNOTATE(
                BCFTOOLS_VIEW_PRE_CIVIC.out.vcf.join(BCFTOOLS_VIEW_PRE_CIVIC.out.tbi),
                annotation_genome_version,
                CIVICPY_UPDATE_CACHE.out.cache.first(),
            )
        }
    }

    //
    // MODULE: BCFTOOLS_VIEW_POST_CIVIC (filter out CIVIC-annotated variants) and TMB
    // Same skip_tmb gate as above — separated for readability (filtering vs TMB calculation)
    //
    if (!skip_tmb) {
        if (!skip_civicpy) {
            BCFTOOLS_VIEW_POST_CIVIC(
                CIVICPY_ANNOTATE.out.vcf.map { meta, vcf -> tuple(meta, vcf, []) },
                [], // regions (unused)
                [], // targets (not necessary -- already restricted by BCFTOOLS_VIEW_PRE_CIVIC)
                [], // samples (unused)
            )
            ch_pre_tmb_vcf_tbi = BCFTOOLS_VIEW_POST_CIVIC.out.vcf
                .join(BCFTOOLS_VIEW_POST_CIVIC.out.tbi)
        } else {
            ch_pre_tmb_vcf_tbi = BCFTOOLS_VIEW_PRE_CIVIC.out.vcf
                .join(BCFTOOLS_VIEW_PRE_CIVIC.out.tbi)
        }

        //
        // MODULE: TMB
        //
        TMB(ch_pre_tmb_vcf_tbi, targets, tmb_vep_config, tmb_mutect2_config)
        ch_versions = ch_versions.mix(TMB.out.versions.first())
    }
    //
    // CNVKIT_BATCH
    //
    // Currently the pipeline does not support matched tumor-normal analysis, so an empty
    //   list is supplied for the normal BAM.
    if (!skip_cnv) {
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
            ch_baits_bed, // note the process labels this "targets", however CNVkit documentation recommends using baits
            tuple([], pon_cnn), // no metadata supplied for the optional panel of normal reference cnn file
            false // boolean, true indicates no tumor sample, multiple normal samples, only output a PON reference
        )
        ch_versions = ch_versions.mix(CNVKIT_BATCH.out.versions.first())
    }

    //
    // MODULE: MSISENSOR2_MSI or MSISENSORPRO_PRO
    //
    // MSIsensor-pro is free for non-profit use but a license is required for commercial use
    // https://github.com/xjtu-omics/msisensor-pro/blob/master/docs/2_License.md
    if (!skip_msi) {
        if (use_msi_pro) {
            MSISENSORPRO_PRO(
                ch_bam_and_index,
                ch_msi_pro_sites,
                [[:], []], // fasta and fai are only required for CRAM format
                [[:], []],
            )
            ch_versions = ch_versions.mix(MSISENSORPRO_PRO.out.versions.first())
        }
        else {
            // Currently the pipeline does not support matched tumor-normal analysis, so an empty
            //   list is supplied for the normal BAM. No interval list is passed.
            // An optional scan file can be provided via --msisensor2_scan (e.g. for non-human panels).
            ch_bam_for_msi = ch_bam_and_index.map { meta, bam, bai -> tuple(meta, bam, bai, [], [], []) }
            ch_msi2_scan_file = ch_msi2_scan.map { _meta, scan -> scan }
            GIT_CLONEMSISENSOR2MODEL(msi_sensor2_model_name)
            ch_versions = ch_versions.mix(GIT_CLONEMSISENSOR2MODEL.out.versions.first())
            MSISENSOR2_MSI(
                ch_bam_for_msi,
                ch_msi2_scan_file,
                GIT_CLONEMSISENSOR2MODEL.out.model.collect(),
            )
            ch_versions = ch_versions.mix(MSISENSOR2_MSI.out.versions.first())
        }
    }


    //
    // MODULE: RIKER_MULTI
    //
    ch_riker_bam = ch_bam_and_index.map { meta, bam, bai ->
        tuple(meta, bam, bai, [], [], [], [], baits[1], targets[1], [], [], [])
    }
    RIKER_MULTI(
        ch_riker_bam,
        ch_fasta.join(ch_fasta_fai).first(),
    )
    ch_multiqc_files = ch_multiqc_files.mix(
        RIKER_MULTI.out.alignment_metrics.collect { _meta, metric -> metric },
        RIKER_MULTI.out.base_dist.collect { _meta, metric -> metric },
        RIKER_MULTI.out.mean_qual.collect { _meta, metric -> metric },
        RIKER_MULTI.out.qual_dist.collect { _meta, metric -> metric },
        RIKER_MULTI.out.gcbias_detail.collect { _meta, metric -> metric },
        RIKER_MULTI.out.gcbias_summary.collect { _meta, metric -> metric },
        RIKER_MULTI.out.isize_metrics.collect { _meta, metric -> metric },
        RIKER_MULTI.out.isize_histogram.collect { _meta, metric -> metric },
        RIKER_MULTI.out.hybcap_metrics.collect { _meta, metric -> metric },
    )

    //
    // MODULE: PERBASE
    //
    PERBASE(ALIGNBAM.out.bam_bai, ch_fasta.join(ch_fasta_fai).first())
    ch_versions = ch_versions.mix(PERBASE.out.versions.first())

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            "${process}:\n${tool_versions.unique().sort().join('\n')}"
        }

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'twistcgp_software_mqc_versions.yml',
            sort: true,
            newLine: true,
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    summary_params = paramsSummaryMap(
        workflow,
        parameters_schema: "nextflow_schema.json",
    )
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
    )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)

    def multiqc_config_files = multiqc_config
        ? [file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true), file(multiqc_config, checkIfExists: true)]
        : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'twistcgp'],
                files,
                multiqc_config_files,
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )

    emit:
    multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions = ch_versions // channel: [ path(versions.yml) ]
}
