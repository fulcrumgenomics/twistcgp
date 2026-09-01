# fulcrumgenomics/twistcgp: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 2.0.0 - 2026-08-26

### Added

- Added GATK4 FilterMutectCalls after Mutect2 variant calling
- Added GATK4 LearnReadOrientationModel to learn strand artifact priors from f1r2 counts for orientation bias filtering (e.g. FFPE deamination)
- Added GATK4 GetPileupSummaries to summarize read support at known germline variant sites for downstream contamination estimation
- Added GATK4 CalculateContamination to estimate cross-sample contamination; wired with GetPileupSummaries outputs into FilterMutectCalls for improved variant filtering
- Added BCFTOOLS_VIEW pre-filtering step prior to TMB calculation
- Added `--tmb_popaf_cutoff` and `--tmb_vaf_cutoff` parameters
- Added `--skip_cnv`, `--skip_msi`, and `--skip_tmb` parameters to allow skipping CNV calling, MSI analysis, and TMB calculation respectively
- Added gnomAD genome allele frequencies (`--af_gnomadg`) to VEP annotation so population filtering covers intronic/non-coding variants (which gnomAD exome does not); pyTMB now consumes the `gnomADg_*` fields

### Fixed

- ALIGNBAM now runs under Singularity: `findutils` and `coreutils` are added to the container, so `find`/`cat`/`touch` are present in the conda-only Singularity image (which has no base OS)
- ALIGNBAM stub now reports the `bwa-mem2` version, matching the container and the `script:` block; previously it shelled out to `bwa` and emitted stderr into `versions.yml` (#99)
- Bumped pinned `picard/markduplicates` to nf-core/modules `2b5333d3d` so the stub emits a `.bai` alongside the `.bam`; previously the join with `.bai` was empty under `-stub` and downstream MSI / GATK steps were silently skipped (#101)
- VEP `--custom` now references the staged file's basename, fixing failures when `--cosmic_vcf` is a remote URL (e.g. `s3://`) on Lifebit/Fusion (#95)

### Changed

- Replaced `fastp` with `chelae/trim` (CHELAE_TRIM) for adapter and quality trimming ([#112](https://github.com/fulcrumgenomics/twistcgp/pull/112))
- Replaced `picard/collectmultiplemetrics` and `picard/collecthsmetrics` with `riker/multi` (RIKER_MULTI) for metrics collection ([#110](https://github.com/fulcrumgenomics/twistcgp/pull/110))
- Replaced the `bwamem2/index` nf-core module with `bwamem3/index` for reference genome indexing ([#125](https://github.com/fulcrumgenomics/twistcgp/pull/125))
- ALIGNBAM now aligns with `bwa-mem3 mem` instead of `bwa-mem2` ([#125](https://github.com/fulcrumgenomics/twistcgp/pull/125))
- Replaced `fgbio/fastqtobam` with `fgumi/extract` (FGUMI_EXTRACT) for FASTQ to unmapped BAM conversion ([#113](https://github.com/fulcrumgenomics/twistcgp/pull/113))
- Replaced `fgbio ZipperBams` with `fgumi zipper` in ALIGNBAM, streamed straight into sort; fgbio and its Java runtime are no longer used ([#132](https://github.com/fulcrumgenomics/twistcgp/pull/132))
- Replaced `samtools fastq` with `fgumi fastq` in ALIGNBAM ([#131](https://github.com/fulcrumgenomics/twistcgp/pull/131))
- Replaced `picard/markduplicates` with `fgumi dedup` in a new local DEDUPBAM module, and `samtools sort` with `fgumi sort`; samtools and picard are no longer used for alignment or duplicate marking ([#135](https://github.com/fulcrumgenomics/twistcgp/pull/135))
- Raised the `--tmb_vaf_cutoff` default from 0.05 to 0.10, tightening TMB pre-filtering ([#84](https://github.com/fulcrumgenomics/twistcgp/pull/84))
- Updated nf-core template to v3.5.2
- Bumped minimum Nextflow version to 25.04.0
- Upgraded nf-schema plugin from 2.4.2 to 2.5.1
- Applied Nextflow strict syntax: `Channel.` to `channel.`, named closure params, explicit `script:` labels
- Fixed closure parameter shadowing `vcf` variable for Nextflow 26.x compatibility
- Removed the MSISENSOR2_SCAN module — MSIsensor2 no longer auto-generates a scan file and now uses only the ML model by default (no scan file or interval list required for human genomes)
- **Breaking:** Samplesheet `sample` column is now required to be unique across rows; previously-accepted multi-row-per-sample inputs (intended for multi-lane fastqs) were silently lossy and now fail validation. Merge lane-level fastqs before running the pipeline.
- **Breaking:** Replaced the single `--msisensor_scan` parameter with two tool-scoped parameters: `--msisensor2_scan` (MSIsensor2 optional scan, primarily for non-human panels) and `--msisensor_pro_sites` (MSIsensor-pro, accepts a scan list or a trained baseline). The MSIsensor-pro path now explicitly supports baseline inputs, which are recommended for production use. Fixes [#91](https://github.com/fulcrumgenomics/twistcgp/issues/91).
- **Breaking:** Renamed the `arm` profile to `emulate_amd64` (amd64 emulation under Docker) and added a new `arm64` profile for native arm64 execution via Wave. Anyone invoking `-profile arm` must switch to `-profile emulate_amd64` (or `arm64`).

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
