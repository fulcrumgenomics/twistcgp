//
// PREPARE INDICES
//

// Initialize channels based on params or indices that were just built
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run
// Condition is based on params.step and params.tools
// If an extra condition exists, it's specified in comments

include { TABIX_TABIX as TABIX_PON } from '../../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as TABIX_POPULATION_GERMLINE } from '../../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as TABIX_COSMIC } from '../../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as TABIX_GNOMAD } from '../../../modules/nf-core/tabix/tabix/main'

workflow PREPARE_INDICES {
    take:
    ch_pop_germline_resource // channel: val(meta), path(vcf)
    ch_pon_vcf // channel: val(meta), path(vcf)
    ch_cosmic_vcf // channel: val(meta), path(vcf)
    ch_gnomad_vcf // channel: val(meta), path(vcf)


    main:
    versions = Channel.empty()

    TABIX_POPULATION_GERMLINE(ch_pop_germline_resource)
    TABIX_PON(ch_pon_vcf)
    TABIX_COSMIC(ch_cosmic_vcf)
    TABIX_GNOMAD(ch_gnomad_vcf)

    versions = versions.mix(TABIX_POPULATION_GERMLINE.out.versions)
    versions = versions.mix(TABIX_PON.out.versions)
    versions = versions.mix(TABIX_COSMIC.out.versions)
    versions = versions.mix(TABIX_GNOMAD.out.versions)



    emit:
    ch_germline_resource_tbi = TABIX_POPULATION_GERMLINE.out.tbi.collect() // channel: val(meta), path(*.vcf.gz.tbi)
    ch_pon_tbi = TABIX_PON.out.tbi.collect() // channel: val(meta), path(*.vcf.gz.tbi)
    ch_cosmic_tbi = TABIX_COSMIC.out.tbi.collect() // channel: val(meta), path(*.vcf.gz.tbi)
    ch_gnomad_tbi = TABIX_GNOMAD.out.tbi.collect() // channel: val(meta), path(*.vcf.gz.tbi)

    versions // channel: [ versions.yml ]
}
