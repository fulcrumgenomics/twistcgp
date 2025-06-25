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
workflow PREPARE_INDICES {
    take:
    ch_pop_germline_resource // channel: val(meta), path(vcf)
    ch_pon_vcf // val(meta), path(vcf)

    main:
    versions = Channel.empty()

    TABIX_POPULATION_GERMLINE(ch_pop_germline_resource)
    TABIX_PON(ch_pon_vcf)

    versions = versions.mix(TABIX_POPULATION_GERMLINE.out.versions)
    versions = versions.mix(TABIX_PON.out.versions)

    emit:
    ch_germline_resource_tbi = TABIX_POPULATION_GERMLINE.out.tbi.collect() // channel: val(meta), path(*.vcf.gz.tbi)
    ch_pon_tbi = TABIX_PON.out.tbi.collect() // channel: val(meta), path(*.vcf.gz.tbi)
    versions // channel: [ versions.yml ]
}
