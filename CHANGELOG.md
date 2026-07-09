# fulcrumgenomics/twistcgp: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added GATK4 FilterMutectCalls after Mutect2 variant calling
- Added GATK4 LearnReadOrientationModel to learn strand artifact priors from f1r2 counts for orientation bias filtering (e.g. FFPE deamination)
- Added GATK4 GetPileupSummaries to summarize read support at known germline variant sites for downstream contamination estimation
- Added GATK4 CalculateContamination to estimate cross-sample contamination; wired with GetPileupSummaries outputs into FilterMutectCalls for improved variant filtering
- Added BCFTOOLS_VIEW pre-filtering step prior to TMB calculation
- Added `--tmb_popaf_cutoff` and `--tmb_vaf_cutoff` parameters
- Added `--skip_cnv`, `--skip_msi`, and `--skip_tmb` parameters to allow skipping CNV calling, MSI analysis, and TMB calculation respectively

### Fixed

- ALIGNBAM stub now reports the `bwa-mem2` version, matching the container and the `script:` block; previously it shelled out to `bwa` and emitted stderr into `versions.yml` (#99)
- Bumped pinned `picard/markduplicates` to nf-core/modules `2b5333d3d` so the stub emits a `.bai` alongside the `.bam`; previously the join with `.bai` was empty under `-stub` and downstream MSI / GATK steps were silently skipped (#101)
- VEP `--custom` now references the staged file's basename, fixing failures when `--cosmic_vcf` is a remote URL (e.g. `s3://`) on Lifebit/Fusion (#95)
- Removed a duplicate `gatk4/getpileupsummaries` key from `modules.json` (JSON silently kept the last entry, so this was latent)
- ALIGNBAM now writes the ZipperBams input to a sorted intermediate file instead of streaming through `/dev/stdout`, fixing an "Exec format error" under Singularity/Apptainer
- ALIGNBAM strips `/1` and `/2` mate suffixes from uBAM QNAMEs before alignment, so ZipperBams' read-name check no longer fails on `fgumi extract` output (workaround until fgumi#486)

### Changed

- Replaced `fgbio FastqToBam` with `fgumi extract` for FASTQ-to-unaligned-BAM conversion (behavior-preserving: read structure pinned to `+T`, all-template, matching FastqToBam; UMI extraction available by changing `--read-structures`)
- Replaced the `bwamem2/index` nf-core module with `bwamem3/index` for reference genome indexing
- ALIGNBAM now aligns with `bwa-mem3` instead of `bwa-mem2` (`bwa-mem3 mem`); ZipperBams (fgbio) and samtools sort are unchanged
- Updated nf-core template to v3.5.2
- Bumped minimum Nextflow version to 25.04.0
- Upgraded nf-schema plugin from 2.4.2 to 2.5.1
- Applied Nextflow strict syntax: `Channel.` to `channel.`, named closure params, explicit `script:` labels
- Fixed closure parameter shadowing `vcf` variable for Nextflow 26.x compatibility
- Samplesheet `sample` column is now required to be unique across rows; previously-accepted multi-row-per-sample inputs (intended for multi-lane fastqs) were silently lossy and now fail validation. Merge lane-level fastqs before running the pipeline.
- **Breaking:** Replaced the single `--msisensor_scan` parameter with two tool-scoped parameters: `--msisensor2_scan` (MSIsensor2 optional scan, primarily for non-human panels) and `--msisensor_pro_sites` (MSIsensor-pro, accepts a scan list or a trained baseline). The MSIsensor-pro path now explicitly supports baseline inputs, which are recommended for production use. Fixes [#91](https://github.com/fulcrumgenomics/twistcgp/issues/91).

## 1.1.0dev

### Changes

- Removed MSISENSOR2_SCAN module — msisensor2 no longer auto-generates a scan file
- MSIsensor2 now uses only the ML model by default (no scan file or interval list required for human genomes)
- The `--msisensor_scan` parameter is now optional for msisensor2 (useful for non-human panels) and remains used by msisensor-pro

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
