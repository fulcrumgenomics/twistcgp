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
    reports = Channel.empty()
    vcf_ann = Channel.empty()
    tab_ann = Channel.empty()
    json_ann = Channel.empty()
    versions = Channel.empty()

    VCF_ANNOTATE_SNPEFF(vcf, annotation_genome_version, snpeff_cache)

    reports = reports.mix(VCF_ANNOTATE_SNPEFF.out.reports.map { meta, reports -> [reports] })
    vcf_ann = vcf_ann.mix(VCF_ANNOTATE_SNPEFF.out.vcf_tbi)
    versions = versions.mix(VCF_ANNOTATE_SNPEFF.out.versions)

    vcf_for_vep = vcf.map { meta, vcf -> [meta, vcf, []] }
    VCF_ANNOTATE_ENSEMBLVEP(
        vcf_for_vep,
        fasta,
        annotation_genome_version,
        ensemblvep_info.map { it[2] }, //species
        ensemblvep_info.map { it[-1] }, // cache version
        vep_cache.map { _meta, cache -> cache }, // path to cache if given
        vep_extra_files,
    )

    reports = reports.mix(VCF_ANNOTATE_ENSEMBLVEP.out.reports)
    vcf_ann = vcf_ann.mix(VCF_ANNOTATE_ENSEMBLVEP.out.vcf_tbi)
    tab_ann = tab_ann.mix(VCF_ANNOTATE_ENSEMBLVEP.out.tab)
    json_ann = json_ann.mix(VCF_ANNOTATE_ENSEMBLVEP.out.json)
    versions = versions.mix(VCF_ANNOTATE_ENSEMBLVEP.out.versions)

    emit:
    vcf_ann // channel: [ val(meta), vcf.gz, vcf.gz.tbi ]
    tab_ann
    json_ann
    reports //    path: *.html
    versions //    path: versions.yml
}
