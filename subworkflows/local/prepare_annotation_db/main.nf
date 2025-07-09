//
// PREPARE ANNOTATION DB (SnpEff + VEP)
//

// Initialize channels based on params or indices that were just built
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run
// Condition is based on params.step and params.tools
// If an extra condition exists, it's specified in comments

include { ENSEMBLVEP_DOWNLOAD } from '../../../modules/nf-core/ensemblvep/download/main'
include { SNPEFF_DOWNLOAD } from '../../../modules/nf-core/snpeff/download/main'


workflow PREPARE_ANNOTATION_DB {
    take:
    ensembl_cache_version // channel: [mandatory] tuple val(meta), val(vep_cache_version)
    snpeff_db // channel: [mandatory] tuple val(meta), val(snpeff_db)

    main:
    versions = Channel.empty()

    ENSEMBLVEP_DOWNLOAD(ensembl_cache_version)
    SNPEFF_DOWNLOAD(snpeff_db)

    // Gather versions of all tools used
    versions = versions.mix(ENSEMBLVEP_DOWNLOAD.out.versions)
    versions = versions.mix(SNPEFF_DOWNLOAD.out.versions)

    emit:
    ensemblvep_cache = ENSEMBLVEP_DOWNLOAD.out.cache.collect() // channel: [ meta, cache ]
    snpeff_cache = SNPEFF_DOWNLOAD.out.cache.collect() // channel: [ meta, cache ]
    versions // channel: [ versions.yml ]
}
