# Steps to Generate Variant Annotation Caches

Variant annotation caches are downloadable files that store information about transcript models, regulatory features and variants for a given species and genome assembly.

The cache is downloaded once and then reused for multiple analyses.

This pipeline will automatically download the Ensembl VEP, SnpEff, and CIViCpy annotation caches if any are missing.

We recommend pre-downloading the VEP and SnpEff cache files for performance.

The CIViCpy annotation cache is small and is downloaded on each pipeline run. If the cache is older than 7 days, the tool will refresh it automatically.

## Ensembl Variant Effect Predictor (VEP) cache

The pipeline accepts either a pre-extracted cache directory or a `.tar.gz` archive via `--ensemblvep_cache`.
If a tarball is supplied, it will be automatically extracted before VEP runs.
Only gzip-compressed archives (`.tar.gz`) are supported; other formats (`.tgz`, `.tar.bz2`) are not.

The version and build of the cache must match the `--ensemblvep_cache_version` and `--annotation_genome_version` parameters provided to the pipeline.

### Option 1: Download with wget (recommended)

1. Download the cache tarball:

```console
wget https://ftp.ensembl.org/pub/release-114/variation/indexed_vep_cache/homo_sapiens_vep_114_GRCh38.tar.gz
```

2. Pass the tarball directly to the pipeline:

```console
nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --baits baits.bed \
   --targets targets.bed \
   --ensemblvep_cache homo_sapiens_vep_114_GRCh38.tar.gz \
   --outdir <OUTDIR>
```

Or extract it first and pass the directory:

```console
tar -xzf homo_sapiens_vep_114_GRCh38.tar.gz

nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --baits baits.bed \
   --targets targets.bed \
   --ensemblvep_cache homo_sapiens/ \
   --outdir <OUTDIR>
```

### Option 2: Download with the VEP installer

1. Install Ensembl VEP, available directly from [github.com/ensembl-vep](https://github.com/Ensembl/ensembl-vep.git) or via mamba/conda ([bioconda::ensembl-vep](https://anaconda.org/bioconda/ensembl-vep)). If using conda, activate your environment.

2. Download the cache, making sure the genome version and database version match the pipeline parameters.

Please note that this download is rate-limited and will take much longer than `wget`.

```console
vep_install -a cf -s homo_sapiens -y GRCh38 -c ~/vep --CONVERT
```

3. Pass the cache directory to the pipeline:

```console
nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --baits baits.bed \
   --targets targets.bed \
   --ensemblvep_cache ~/vep/ \
   --outdir <OUTDIR>
```

Note that `--ensemblvep_cache` should point to the directory containing the `homo_sapiens/` subdirectory:

```console
$ tree -L 1 ~/vep/
~/vep/
├── homo_sapiens
│   └── 114_GRCh38
```

## SnpEff cache

1. Install SnpEff which is available directly from [github.com/snpeff](https://pcingola.github.io/SnpEff/) or install with mamba/conda, [bioconda::snpeff](https://anaconda.org/bioconda/snpeff). If using conda, activate your environment.

2. Download the cache with SnpEff, making sure that the genome version and database version match the pipeline parameters:

```console
snpEff download GRCh38.99 -v
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
   --snpeff_cache "${CONDA_PREFIX}/share/snpeff-5.3.0a-1/data/" \
   --outdir <OUTDIR>
```

Note that the path provided to `--snpeff_cache` should be the parent directory of the cache files.
In this example, SnpEff was installed with conda, so the `--snpeff_cache` would be `${CONDA_PREFIX}/share/snpeff-5.3.0a-1/data/`:

```console
$ tree -L 1 "${CONDA_PREFIX}/share/snpeff-5.3.0a-1/data/"
"${CONDA_PREFIX}/share/snpeff-5.3.0a-1/data/"
├── GRCh38.99
```

## CIViC cache

This pipeline uses CIViCpy, a Python tool for the CIViC knowledgebase.

The [CIViC knowledgebase](https://civicdb.org/welcome) (Clinical Interpretation of Variants in Cancer) is an open-source database that provides curated information about the clinical relevance of genomic variants in cancer. This pipeline will use the CIViC knowledgebase to annotate variants with an "accepted" status, which means the variants were reviewed by users with “Editor” or “Admin” level privileges.

CIViCpy stores its annotation cache in a `pickle` file.

While pickle files are generally [considered insecure](https://docs.python.org/3/library/pickle.html) because arbitrary code can be executed during deserialization, this file is pulled directly from a trusted source.

If you load a pickle file from an untrusted source, a malicious actor could potentially embed code that would execute on your system when the file is unpacked for use.

If pickle files are not compliant with your organization's security policies, you can skip this module with the `--skip-civicpy` parameter.
