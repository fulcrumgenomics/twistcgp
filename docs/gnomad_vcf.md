# Steps to Generate a gnomAD VCF

Tumor mutational burden (TMB) is a total number of somatic mutations present within the cancer genome.
It is crucial to exclude germline variants for the calculation of TMB.
This pipeline uses [Ensembl VEP](https://useast.ensembl.org/index.html) to retrieve frequency data
from the gnomAD [4.1 exomes set](https://gnomad.broadinstitute.org/downloads#v4) and annotate variants.

Any gnomAD VCF can be passed to the pipeline using the `--gnomad_vcf` parameter.
A script is included in the pipeline to prepare a gnomAD VCF that is sub-selected to the genomic
positions included in the targets BED file to facilitate variant annotation.

To run this script:

```console
bash ./assets/scripts/fetch_and_intersect_gnomad_vcfs.sh
```

This will generate a bg-zipped gnomAD VCF file and its corresponding TBI index.

The VCF can be supplied to the pipeline:

```console
nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --baits baits.bed \
   --targets targets.bed \
   --ensemblvep_cache ~/vep/ \
   --gnomad_vcf assets/gnomad_vcf_processing/all_chromosomes.intersect.vcf.bgz \
   --gnomad_tbi assets/gnomad_vcf_processing/all_chromosomes.intersect.vcf.bgz.tbi \

   --outdir <OUTDIR>
```
