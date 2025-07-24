# Steps to Generate Variant Annotation Caches

Variant annotation caches are downloadable files that store information about transcript models, regulatory features and variants for a given species and genome assembly.

The cache is downloaded once and then reused for multiple analyses.

While this pipeline will download both the Ensembl VEP and SnpEff annotation caches if either are missing, we recommend pre-downloading these files for performance.

## Ensembl Variant Effect Predictor (VEP) cache

1. The quickest way to download the VEP cache is with `wget` and `tar`:

```console
wget https://ftp.ensembl.org/pub/release-114/variation/indexed_vep_cache/homo_sapiens_vep_114_GRCh38.tar.gz
tar -xzf homo_sapiens_vep_114_GRCh38.tar.gz
```

2. Alternatively, install Ensembl VEP which is available directly from [github.com/ensembl-vep](https://github.com/Ensembl/ensembl-vep.git) or install with mamba/conda, [bioconda::ensembl-vep](https://anaconda.org/bioconda/ensembl-vep). If using conda, activate your environment.

3. Download the cache with Ensembl VEP, making sure that the genome version and database version match the pipeline parameters.

Please note that this download is rate-limited, and will take much longer than `wget`.

```console
vep_install -a cf -s homo_sapiens -y GRCh38 -c ~/vep --CONVERT
```

3. Pass the cache to the pipeline:

```bash
nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --baits baits.bed \
   --targets targets.bed \
   --ensemblvep_cache ~/vep/ \
   --outdir <OUTDIR>
```

## SnpEff cache

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
   --ensemblvep_cache ~/vep/ \
   --snpeff_cache "${CONDA_PREFIX}/share/snpeff-5.2-1/data/GRCh38.105" \
   --outdir <OUTDIR>
```
