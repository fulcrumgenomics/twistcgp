# Steps to Generate a Germline Resource VCF

An existing population VCF can be used for the germline resource VCF, or a custom one can be generated from a specific population

1. Download the appropriate gzipped [hg38](https://storage.googleapis.com/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz) VCF file from gnomAD.

The pipeline will automatically use `tabix` to index the provided VCF if no index file is provided. If you wish, you can optionally pre-index the VCF:

2. Optionally pre-index the VCF by installing [tabix](https://www.htslib.org/doc/tabix.html), navigating to the directory containing the file and running:

```console
tabix \
  -p vcf \
  af-only-gnomad.hg38.vcf.gz
```
