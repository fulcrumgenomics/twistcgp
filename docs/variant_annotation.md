# Steps to Generate a SnpEff cache

1. Install SnpEff which is available directly from [github.com/snpeff](https://pcingola.github.io/SnpEff/) or install with mamba/conda, [bioconda::snpeff](https://anaconda.org/bioconda/snpeff). If using conda, activate your environment.

2. Download the cache with SnpEff, making sure that the genome version and database version match the pipeline parameters:

```console
snpEff download GRCh38.105 -v
```

3. Pass the cache to the pipeline:

```console
nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --baits baits.bed \
   --targets targets.bed \
   --snpeff_cache "${CONDA_PREFIX}/share/snpeff-5.2-1/data/GRCh38.105" \
   --outdir <OUTDIR>
```
