# Generate a Panel of Normals Reference for CNV Calling

You may want to generate a Panel of Normals (PON) for use in CNV Calling.
The input samples to this process should be BAM files aligned using the same methodology as your experimental samples.
You may use BAM files processed with this pipeline.

## Steps

1. [Install CNVkit](https://github.com/etal/cnvkit?tab=readme-ov-file#installation)

1. [Build a reference `.cnn` file](https://cnvkit.readthedocs.io/en/stable/quickstart.html#build-a-reference-from-normal-samples-and-infer-tumor-copy-ratios)

You will need:
- BED file for the panel
- reference genome fasta file, [GIAB hg38 corrected fasta.gz](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz)
- aligned BAM files for your PON samples

```console
cnvkit.py batch  \
    --normal *normal.bam \
    --targets panel.bed \
    --output-reference pon.cnn \
    --output-dir cnv-kit-pon-reference/
```
