# twistcgp

## Introduction

**twistcgp** is a bioinformatics pipeline for processing data from [Twist Bioscience's](https://www.twistbioscience.com/) TwistCGP product for targeted enrichment of cancer-associated genes.

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->

### Pipeline Steps

1. Index Genome ([`bwa-mem2`](https://github.com/bwa-mem2/bwa-mem2), [`samtools`](https://www.htslib.org/))
1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
1. Trim Adapters ([`fastp`](https://github.com/OpenGene/fastp))
1. Fastq to BAM ([`fgbio FastqToBam`](http://fulcrumgenomics.github.io/fgbio/tools/latest/FastqToBam.html))
1. Align ([`bwa-mem2`](https://github.com/bwa-mem2/bwa-mem2))
1. Mark Duplicates ([`picard MarkDuplicates`](https://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates))
1. Collect Metrics ([`picard CollectMultipleMetrics`](https://broadinstitute.github.io/picard/command-line-overview.html#CollectMultipleMetrics), [`perbase`](https://github.com/sstadick/perbase))
1. Present QC ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow.
> Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `nextflow run twistcpg/main.nf -profile "test,[docker|singularity|conda]" --outdir ./results` before running the workflow on actual data.

For a full list of available options run `nextflow run twistcpg/main.nf --help --show_hidden`.

### Prepare a Samplesheet

First, prepare a samplesheet with your input data that looks as follows:

```text
sample,fastq_1,fastq_2
ILLUMINA_PAIRED_END,assets/test-data/fastq/Illumina_TestReads_R1_001.fastq.gz,assets/test-data/fastq/Illumina_TestReads_R2_001.fastq.gz
MGI_SINGLE_END,assets/test-data/fastq/MGI_TestReads_1.fq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).
The sample column provides a unique identifier for the given sample.

### Obtain a Genome

The TwistCGP panel was designed using the hg38 Genome in a Bottle (GIAB) reference genome FASTA file which can be obtained from [GIAB](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz).

### (Optionally) Pre-Generate a Genome Index

Because this pipeline uses bwa-mem2 for alignment, 87GB of memory are required to generate the human genome index.
Alternatively, this index can be built without the pipeline and the directory supplied using the `--bwa` parameter.
See [docs/bwamem2_index.md](/docs/bwamem2_index.md) for details.

Additionally, the genome index can be saved to the output directory for future use by supplying the `--save_reference` parameter.

### (Optionally) Provide Adapter Sequences

If sequencing data is likely to include adapter sequences, providing these sequences in FASTA format will allow `fastp` to trim those sequences prior to alignment.
The adapter sequences can be supplied to the pipeline using the `--adapters_fasta` parameter.

### Run the Pipeline

Now, you can run the pipeline using:

```bash
nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

twistcgp was originally written by Zach Norgaard of [Fulcrum Genomics](https://fulcrumgenomics.com/).

We thank the following people for their extensive assistance in the development of this pipeline:

- Nils Homer
- Tim Dunn

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use fulcrumgenomics/twistcgp for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
