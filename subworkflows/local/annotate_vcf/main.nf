//
// ANNOTATION: SnpEff and VEP
//

include { VCF_ANNOTATE_ENSEMBLVEP } from '../../nf-core/vcf_annotate_ensemblvep/main'
include { VCF_ANNOTATE_SNPEFF } from '../../nf-core/vcf_annotate_snpeff/main'

workflow VCF_ANNOTATE {
    take:
    vcf // channel: [ val(meta), vcf ]
    fasta
    annotation_genome_version
    ensemblvep_info
    snpeff_cache
    vep_cache
    vep_extra_files

    main:
    versions = Channel.empty()

    VCF_ANNOTATE_SNPEFF(vcf, annotation_genome_version, snpeff_cache)
    vcf_for_vep = VCF_ANNOTATE_SNPEFF.out.vcf_tbi.map { meta, vcf, tbi -> [meta, vcf, []] } // no optional custom files

    VCF_ANNOTATE_ENSEMBLVEP(
        vcf_for_vep,
        fasta,
        annotation_genome_version,
        ensemblvep_info.map { it[2] }, //species
        ensemblvep_info.map { it[-1] }, // cache version
        vep_cache.map { _meta, cache -> cache }, // path to cache if given
        vep_extra_files,
    )

    versions = versions.mix(VCF_ANNOTATE_SNPEFF.out.versions)
    versions = versions.mix(VCF_ANNOTATE_ENSEMBLVEP.out.versions)

    emit:
    vcf_ann = VCF_ANNOTATE_ENSEMBLVEP.out.vcf_tbi // channel: [ val(meta), vcf.gz, vcf.gz.tbi ]
    tab_ann = VCF_ANNOTATE_ENSEMBLVEP.out.tab // channel: [ val(meta), path(tab) ]
    json_ann = VCF_ANNOTATE_ENSEMBLVEP.out.json // channel: [ val(meta), path(json) ]
    reports = VCF_ANNOTATE_ENSEMBLVEP.out.reports // path: *.html
    versions // path: versions.yml
}
