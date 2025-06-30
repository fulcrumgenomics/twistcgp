//
// TUMOR_MUTATIONAL_BURDEN
//

// Initialize channels based on params or indices that were just built
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run
// Condition is based on params.step and params.tools
// If an extra condition exists, it's specified in comments
include { TMB } from '../../../modules/local/tmb/main'


workflow CALCULATE_TMB {
    take:
    ch_annotated_vcf // channel: [ val(meta), vcf.gz, vcf.gz.tbi ]
    ch_fasta // channel: val(reference meta), path(reference FASTA file)
    targets //tuple of meta and targets regions file read in from --targets
    variant_annotation_config // path to variant_annotation config
    variant_calling_config // path to variant_caller config

    main:
    versions = Channel.empty()

    // TODO: norm VCF with bcf_tools norm
    TMB(ch_annotated_vcf, variant_annotation_config, variant_calling_config, targets[1])

    versions = versions.mix(TMB.out.versions)

    emit:
    versions
}
