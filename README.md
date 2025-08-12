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
1. Variant Calling via local Assembly of Haplotypes ([`gatk4/mutect2`](https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2))
1. Annotate Variants ([`SnpEff`](https://pcingola.github.io/SnpEff/), [`Ensembl VEP`](https://useast.ensembl.org/info/docs/tools/vep/index.html), [`CIViCpy`](https://github.com/griffithlab/civicpy))
1. Calculate Tumor Mutational Burden ([`pyTMB`](https://github.com/bioinfo-pf-curie/TMB))
1. Call CNVs ([`CNVkit`](https://cnvkit.readthedocs.io/en/stable/index.html))
1. Identify MSI ([`MSIsensor2`](https://github.com/niu-lab/msisensor2) or [`MSIsensor-pro`](https://github.com/xjtu-omics/msisensor-pro))
1. Collect Metrics ([`picard CollectHsMetrics`](https://broadinstitute.github.io/picard/command-line-overview.html#CollectHsMetrics), [`picard CollectMultipleMetrics`](https://broadinstitute.github.io/picard/command-line-overview.html#CollectMultipleMetrics), [`perbase`](https://github.com/sstadick/perbase))
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

### Obtain list of Baits & Targets

You will need a BED or Interval List file for (1) the panel baits and (2) the panel targets.

BED files should follow the [UCSC BED format specifications](https://genome.ucsc.edu/FAQ/FAQformat.html#format1); interval list files should adhere to [GATK interval list conventions](https://gatk.broadinstitute.org/hc/en-us/articles/360035531852-Intervals-and-interval-lists).

Targets will be padded prior to variant calling; the padding size can be adjusted using the `--target_padding` parameter (default: 100, which adds 100 bp on each side of the interval).

> [!NOTE]
> If you lack the baits file, you can provide the panel targets for both arguments.
> Providing the targets as the baits will invalidate the bait specific metrics in the picard `HsMetrics`.
> Additionally, CNV calls from CNVkit may be noiser due to inaccurate modeling of bait locations.

The TwistCGP baits and targets files are available from Twist after purchasing the TwistCGP product.

### (Optionally) Provide Adapter Sequences

If sequencing data is likely to include adapter sequences, providing these sequences in FASTA format will allow `fastp` to trim those sequences prior to alignment.
The adapter sequences can be supplied to the pipeline using the `--adapters_fasta` parameter.

### Optional Time and Resource Saving Setup

<details> <summary>Pre-Generate a Genome Index</summary>

Because this pipeline uses bwa-mem2 for alignment, 87GB of memory are required to generate the human genome index.
Alternatively, this index can be built without the pipeline and the directory supplied using the `--bwa` parameter.
See [docs/bwamem2_index.md](/docs/bwamem2_index.md) for details.

Additionally, the genome index can be saved to the output directory for future use by supplying the `--save_reference` parameter.

</details>

<details> <summary>Pre-Generate a MSI Genome Scan List</summary>

Generation of the MSIsensor2 or MSIsensor-pro microsatellite scan list requires a space intensive, uncompressed reference genome.
To save time and space you can supply the scan list generated by MSIsensor2 (or MSIsensor-pro) using the `--msisensor_scan` parameter.
See [docs/msisensor_scan.md](/docs/msisensor_scan.md) for details.

Additionally, the MSI scan list can be saved to the output directory for future use by supplying the `--save_reference` parameter.

</details>

<details> <summary>Pre-Generate Variant Annotation Caches</summary>

SnpEff and Ensembl VEP require many large files known as a cache with which to annotate variants.

To use a pre-downloaded cache for variant annotation, supply the parameters `--snpeff_cache` and/or `--ensemblvep_cache` with the path to the root of the annotation cache folder.

For details on how to generate each cache see [docs/variant_annotation.md](/docs/variant_annotation.md).

If a cache is not provided, the pipeline will automatically download it (which will add computation time).

</details>

### Optional Variant Calling Resource Files

<details> <summary>Population Germline Resource VCF</summary>

This pipeline uses [Mutect2](https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2) to perform somatic variant calling on local haplotypes.

While Mutect2 does not require a germline resource or a panel of normals (PoN) to run, both are recommended.

The germline resource VCF encapsulates population allele frequencies of known germline variants (typically from healthy individuals).

These frequencies are used by Mutect2 to model the likelihood that a specific variant is somatic or inherited.
The provided VCF file must contain allele frequencies.

The germline resource VCF can be supplied to the pipeline using the `--population_germline_vcf` parameter.

The corresponding TBI index can be supplied using the `--population_germline_tbi` parameter.

See [docs/germline_resource_vcf.md](/docs/germline_resource_vcf.md) for more details on how to generate this input.

<details><summary>Example Germline Resource VCF Records</summary>

```
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO
 *      1       10067   .       T       TAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCC      30.35   PASS    AC=3;AF=7.384E-5
 *      1       10108   .       CAACCCT C       46514.32        PASS    AC=6;AF=1.525E-4
 *      1       10109   .       AACCCTAACCCT    AAACCCT,*       89837.27        PASS    AC=48,5;AF=0.001223,1.273E-4
 *      1       10114   .       TAACCCTAACCCTAACCCTAACCCTAACCCTAACCCCTAACCCTAACCCTAACCCTAACCCTAACCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCCTAACCCTAACCCTAAACCCTA  *,CAACCCTAACCCTAACCCTAACCCTAACCCTAACCCCTAACCCTAACCCTAACCCTAACCCTAACCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCCTAACCCTAACCCTAAACCCTA,T      36728.97        PASS    AC=55,9,1;AF=0.001373,2.246E-4,2.496E-5
 *      1       10119   .       CT      C,*     251.23  PASS    AC=5,1;AF=1.249E-4,2.498E-5
 *      1       10120   .       TA      CA,*    14928.74        PASS    AC=10,6;AF=2.5E-4,1.5E-4
 *      1       10128   .       ACCCTAACCCTAACCCTAAC    A,*     285.71  PASS    AC=3,1;AF=7.58E-5,2.527E-5
 *      1       10131   .       CT      C,*     378.93  PASS    AC=7,5;AF=1.765E-4,1.261E-4
 *      1       10132   .       TAACCC  *,T     18025.11        PASS    AC=12,2;AF=3.03E-4,5.049E-5
```

</details>
</details>

<details> <summary>Panel of Normals VCF</summary>

While a panel of normals (PoN) VCF is not required for Mutect2 to run, it is recommended. A PoN is a VCF that contains sites found across multiple "normal" samples (e.g., derived from healthy tissue that is believed to not have somatic alterations), ideally from the same sequencing preparation, pipeline, platform, etc. as the tumor samples. While the germline resource helps model population variants, the PoN VCF filters out technical artifacts to improve the quality of the variant calling analyses.

The panel of normals VCF can be supplied to the pipeline using the `--pon_vcf` parameter.

Its corresponding TBI file can be supplied using the `--pon_tbi` parameter.

See [docs/panel_of_normals_vcf.md](/docs/panel_of_normals_vcf.md) for more details on how to generate a panel of normals VCF.

</details>

<details> <summary>Panel of Normal `.cnn` Reference for CNV Calling</summary>

You may supply a Panel of Normal (PON) reference `.cnn` file for use with [CNVkit](https://cnvkit.readthedocs.io/en/stable/index.html).
For details on how to generate this file see [docs/cnvkit_pon.md](/docs/cnvkit_pon.md).

If you do not supply a PON reference, a "flat" reference will be used which assumes equal coverage across the panel regions.

### (Optionally) Pre-Generate a SnpEff Cache

SnpEff requires many large files known as a cache with which to annotate variants.

To use a pre-downloaded cache for variant annotation, supply the parameter `--snpeff_cache` with the path to the root of the annotation cache folder.

For details on how to generate the cache see [docs/variant_annotation.md](/docs/variant_annotation.md).

If a cache is not provided, the pipeline will automatically download it (which will add computation time).

### (Optionally) Generate a gnomAD VCF for Tumor Mutation Burden Calculation

Tumor mutational burden (TMB) is a total number of somatic mutations present within the cancer genome.
It is crucial to exclude germline variants for the calculation of TMB. This pipeline expects a
VCF derived from [gnomAD](https://gnomad.broadinstitute.org/).

See [docs/gnomad_vcf.md](/docs/gnomad_vcf.md) for details on how to generate a gnomAD VCF.

### Run the Pipeline

Now, you can run the pipeline using:

```console
nextflow run twistcgp/main.nf \
   -profile <docker/singularity/conda> \
   --fasta hg38.fa \
   --input samplesheet.csv \
   --baits baits.bed \
   --targets targets.bed \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

twistcgp was originally written by Erin McAuley and Zach Norgaard of [Fulcrum Genomics](https://fulcrumgenomics.com/).

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
