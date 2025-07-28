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
include { MSISENSOR2_SCAN } from '../../../modules/nf-core/msisensor2/scan/main'
include { MSISENSORPRO_SCAN } from '../../../modules/nf-core/msisensorpro/scan/main'

workflow PREPARE_GENOME {
    take:
    fasta // channel: [mandatory] fasta
    msi_pro // boolean: if true, will run MSISensorPro else MSISensor2

    main:
    versions = Channel.empty()

    BWAMEM2_INDEX(fasta)
    // If aligner is bwa-mem
    SAMTOOLS_FAIDX(fasta, [[id: 'no_fai'], []], false)
    SAMTOOLS_DICT(fasta)

    if (msi_pro) {
        MSISENSORPRO_SCAN(fasta)
    } else {
        MSISENSOR2_SCAN(fasta.map {it -> it[1]}, fasta.map {it -> "${it[1].baseName}.msisensor_scan.list"})
    }
    msi_scan = msi_pro
        ? MSISENSORPRO_SCAN.out.list
        : MSISENSOR2_SCAN.out.scan.map {it -> tuple([id: 'scan'], it) }

    // Gather versions of all tools used
    versions = versions.mix(BWAMEM2_INDEX.out.versions)
    versions = versions.mix(SAMTOOLS_FAIDX.out.versions)

    emit:
    bwa = BWAMEM2_INDEX.out.index.collect() // path: bwa/*
    dict = SAMTOOLS_DICT.out.dict.collect() // path: genome.fasta.dict
    fasta_fai = SAMTOOLS_FAIDX.out.fai.collect() // path: genome.fasta.fai
    fasta_gzi = SAMTOOLS_FAIDX.out.gzi.collect() // path: genome.fasta.gz.gzi
    msi_scan = msi_scan.collect() // path: genome.msisensor_scan.list
    versions // channel: [ versions.yml ]
}
