# Generate a Panel of Normals Reference for CNV Calling

You may want to generate a Panel of Normals (PON) for use in CNV Calling.
The input samples to this process should be BAM files produced using the same methodology as your experimental samples.
You may use BAM files processed with this pipeline.

## Steps

1. [Install CNVkit](https://github.com/etal/cnvkit?tab=readme-ov-file#installation)

2. [Calculate Bin Sizes](https://cnvkit.readthedocs.io/en/stable/pipeline.html#autobin)

You will need:

- BED file for the panel baits.
  Note the command line argument is called "targets"; however, [the CNVkit documentation](https://cnvkit.readthedocs.io/en/stable/quickstart.html#build-a-reference-from-normal-samples-and-infer-tumor-copy-ratios) recommends providing the baits.
- aligned and indexed BAM files for your PON samples, see [samtools index](https://www.htslib.org/doc/samtools-index.html)

Using those files, run:

```console
cnvkit.py autobin  \
    --normal *normal.bam \
    --targets baits.bed \
    --method hybrid
```

This will generate a summary of "Target" and "Antitarget" bin coverage depths with recommended bin sizes.

```console
            Depth    Bin size
Target:    	2075.369 48
Antitarget:	3.347    29880
```

Use these bin sizes for the next step.

3. [Build a reference `.cnn` file](https://cnvkit.readthedocs.io/en/stable/quickstart.html#build-a-reference-from-normal-samples-and-infer-tumor-copy-ratios)

You will need:

- BED file for the panel baits.
  Note the command line argument is called "targets"; however, [the CNVkit documentation](https://cnvkit.readthedocs.io/en/stable/quickstart.html#build-a-reference-from-normal-samples-and-infer-tumor-copy-ratios) recommends providing the baits.
- reference genome fasta file, [GIAB hg38 corrected fasta.gz](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz)
- aligned BAM files for your PON samples
- the bin sizes identified in the previous step

Using those files, run:

```console
cnvkit.py batch  \
    --normal *normal.bam \
    --targets baits.bed \
    --fasta GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta \
    --output-reference pon.cnn \
    --output-dir cnv-kit-pon-reference/ \
    --target-avg-size 48 \
    --antitarget-avg-size 29880
```

This will generate a `pon.cnn` that can be passed to the pipeline using the `--pon_cnn` parameter.
