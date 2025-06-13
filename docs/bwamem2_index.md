# Steps to Generate a bwa-mem2 index

1. Install bwa-mem2 which is available directly from [github.com/bwa-mem2](https://github.com/bwa-mem2/bwa-mem2?tab=readme-ov-file#installation) or install with mamba/conda, [bioconda::bwa-mem2](https://anaconda.org/bioconda/bwa-mem2).

2. Download the reference genome from GIAB, [fasta.gz link](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz).

3. Generate the index

Navigate to the directory containing the reference genome and run:

```console
mkdir bwamem2
bwa-mem2 \
    index \
    -p  bwamem2/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz \
    GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz
```
