# Steps to Generate a Panel of Normals VCF

## Use a Pre-existing VCF

[GATK](https://gatk.broadinstitute.org/hc/en-us/articles/360035890631-Panel-of-Normals-PON) makes public PoN files available to download as part of the GATK resource bundle.

## Create a Customized PoN VCF

### Short Variants and Indels

For short variant discovery, the panel of normals (PoN) is created by running Mutect2 individually on a set of normal samples. The resulting variant calls are combined and can be filtered according to specific criteria. The resultant sites-only VCF file can now be used as a PoN for Mutect2.

1. Install gatk which is available directly from [github.com/broadinstitute/gatk](https://github.com/broadinstitute/gatk?tab=readme-ov-file#quickstart) or install with mamba/conda, [bioconda::gatk](https://anaconda.org/bioconda/gatk).

2. Run Mutect2 in tumor-only mode for each normal sample. If you have a directory containing BAM files from only normal samples, navigate to the directory and run the following:

```console
ls *.bam | xargs -n 1 -I {} bash -c \
'gatk Mutect2 -R reference.fasta -I "{}" --max-mnp-distance 0 -O "$(basename {} .bam).vcf.gz"'
```

3. Create a GenomicsDB from the normal Mutect2 calls:

```console
gatk GenomicsDBImport \
  -R reference.fasta \
  -L intervals.interval_list \
  --genomicsdb-workspace-path pon_db \
  $(for vcf in normal*.vcf.gz; do echo -n "-V $vcf "; done)
```

:warning: The `intervals` argument is required.

4. Combine the normal calls using `CreateSomaticPanelOfNormals`:

```console
gatk CreateSomaticPanelOfNormals \
  -R reference.fasta \
  -V gendb://pon_db \
  -O pon.vcf.gz
```

:white_check_mark: A `--germline-resource` is optional but recommended here. See [germline_resource_vcf](./germline_resource_vcf.md) for details.
