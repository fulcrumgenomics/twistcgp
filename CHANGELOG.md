# fulcrumgenomics/twistcgp: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 - 2026-02-27

Initial release of fulcrumgenomics/twistcgp, a Nextflow pipeline for processing data from Twist Bioscience's TwistCGP product for targeted enrichment of cancer-associated genes.
Created with the [nf-core](https://nf-co.re/) template.

### Features

- Read QC with FastQC and adapter trimming with fastp
- FASTQ to BAM conversion with fgbio FastqToBam
- Alignment with bwa-mem2 and duplicate marking with picard MarkDuplicates
- Variant calling with GATK4 Mutect2
- Variant annotation with SnpEff, Ensembl VEP (including gnomAD and COSMIC), and CIViCpy
- Copy number variant calling with CNVkit
- Microsatellite instability detection with MSIsensor2
- Tumor mutational burden calculation with pyTMB
- Metrics collection with picard CollectHsMetrics, CollectMultipleMetrics, and perbase
- QC reporting with MultiQC
- Genome index preparation subworkflow
- Built on nf-core template v3.3.2
