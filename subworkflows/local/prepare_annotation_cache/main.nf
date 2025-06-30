//
// PREPARE ANNOTATION CACHE
//

// Initialize channels based on params or indices that were just built
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run
// Condition is based on params.step and params.tools
// If an extra condition exists, it's specified in comments

include { SNPEFF_DOWNLOAD } from '../../../modules/nf-core/snpeff/download/main'


workflow PREPARE_ANNOTATION_CACHE {
    take:
    snpeff_info // channel: [mandatory] tuple val(meta), val(snpeff_db)

    main:
    versions = Channel.empty()

    SNPEFF_DOWNLOAD(snpeff_info)

    // Gather versions of all tools used
    versions = versions.mix(SNPEFF_DOWNLOAD.out.versions)

    emit:
    snpeff_cache = SNPEFF_DOWNLOAD.out.cache.collect() // channel: [ meta, cache ]
    versions // channel: [ versions.yml ]
}
