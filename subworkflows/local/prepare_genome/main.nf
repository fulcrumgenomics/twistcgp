//
// PREPARE GENOME
//

// Initialize channels based on params or indices that were just built
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run
// Condition is based on params.step and params.tools
// If and extra condition exists, it's specified in comments

include { BWAMEM2_INDEX } from '../../../modules/nf-core/bwamem2/index/main'
include { SAMTOOLS_FAIDX } from '../../../modules/nf-core/samtools/faidx/main'
include { SAMTOOLS_DICT } from '../../../modules/nf-core/samtools/dict/main'

workflow PREPARE_GENOME {
    take:
    fasta // channel: [mandatory] fasta

    main:
    versions = Channel.empty()

    BWAMEM2_INDEX(fasta)
    // If aligner is bwa-mem
    SAMTOOLS_FAIDX(fasta, [[id: 'no_fai'], []], false)
    SAMTOOLS_DICT(fasta)

    // Gather versions of all tools used
    versions = versions.mix(BWAMEM2_INDEX.out.versions)
    versions = versions.mix(SAMTOOLS_FAIDX.out.versions)

    emit:
    bwa = BWAMEM2_INDEX.out.index.collect() // path: bwa/*
    dict = SAMTOOLS_DICT.out.dict.collect() // path: genome.fasta.dict
    fasta_fai = SAMTOOLS_FAIDX.out.fai.collect() // path: genome.fasta.fai
    versions // channel: [ versions.yml ]
}
