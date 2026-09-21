# Steps to Generate a bwa-mem3 index

1. Install bwa-mem3 which is available directly from [github.com/fg-labs/bwa-mem3](https://github.com/fg-labs/bwa-mem3).

2. Download the reference genome from GIAB, [fasta.gz link](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz).

3. Generate the index

Navigate to the directory containing the reference genome and run:

```console
mkdir bwamem3
bwa-mem3 \
    index \
    -p  bwamem3/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz \
    GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz
```
