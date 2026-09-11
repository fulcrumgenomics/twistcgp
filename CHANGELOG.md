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

- ALIGNBAM stub now reports the `bwa-mem2` version, matching the container and the `script:` block; previously it shelled out to `bwa` and emitted stderr into `versions.yml` (#99)
- Bumped pinned `picard/markduplicates` to nf-core/modules `2b5333d3d` so the stub emits a `.bai` alongside the `.bam`; previously the join with `.bai` was empty under `-stub` and downstream MSI / GATK steps were silently skipped (#101)
- VEP `--custom` now references the staged file's basename, fixing failures when `--cosmic_vcf` is a remote URL (e.g. `s3://`) on Lifebit/Fusion (#95)
- Reference-preparation subworkflow tool versions (`PREPARE_GENOME`/`PREPARE_INDICES`/`PREPARE_ANNOTATION_DB`) are now collated into the software-versions report; previously they were emitted but never captured
- Local per-sample channel joins now use `failOnMismatch`/`failOnDuplicate` so a missing or duplicated sample fails loudly instead of being silently dropped; the optional `GATK4_CALCULATECONTAMINATION` joins intentionally stay lenient (`remainder: true`)
- Miscellaneous refinements: `fasta_gzi` is now a channel rather than a Groovy closure; removed an unused `PICARD_INTERVALLISTTOBED` import; the CNVkit reference tuple uses an empty meta map `[:]` instead of `[]`; tightened the `pon_cnn` schema pattern (`.cnn?` → `.cnn`, was accepting `.cn`); and corrected stale template boilerplate (the `save_reference` help referenced a STAR index; aligned the `pipelines_testdata_base_path` default between `nextflow.config` and the schema)
- Added the missing `gnomADg_REMAINING_AF` population to the pyTMB gnomAD genome polymorphism list in `assets/pytmb_vep.yml` (the exome list already had `gnomADe_REMAINING_AF`); this gnomAD genome population is now excluded during TMB germline filtering

### Changed

- Replaced the local `TMB` module with the nf-core `tmb/pytmb` module (tmb pinned to 1.5.0 in both conda and container; correct `-stub` outputs; upstream nf-test). The `--export` VCF of the variants that fed the TMB calculation is now published alongside the log. Note: the published TMB log is now named `<id>.log` (previously `<id>.tmb.log`).
- **Fix:** Removed the unused `--gnomad_vcf` / `--gnomad_tbi` parameters and the gnomAD `TABIX` staging step. The staged gnomAD VCF was handed to VEP but never referenced (VEP only adds `--custom` for COSMIC); gnomAD allele frequencies come from the VEP cache via `--af_gnomade`/`--af_gnomadg`. Also removed the now-orphaned `docs/gnomad_vcf.md`.
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
