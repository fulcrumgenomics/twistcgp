# Tumor Mutational Burden (TMB) Calculation

This pipeline uses `pyTMB`([Dupain et al., 2024](https://bmcbiol.biomedcentral.com/articles/10.1186/s12915-024-01839-8)) to calculate tumor mutational burden (TMB) from somatic variant calls.

## Overview

pyTMB processes variant call data from an annotated VCF to quantify TMB as the number of qualifying somatic mutations per megabase of effective genome size.

Effective genome size is calculated from the panel target BED file.

In accordance with best practices, this pipeline implements filtering for sequencing depth, variant allele fraction (VAF), known polymorphisms, coding consequences, and quality metrics.

## Parameter Details

### Polymorphisms

| Argument           | Description                                                    |
| ------------------ | -------------------------------------------------------------- |
| `--polymDb gnomad` | Use gnomAD as the population polymorphism database.            |
| `--filterPolym`    | Exclude variants present in the polymorphism database.         |
| `--maf 0.01`       | Remove variants with a population minor allele frequency ≥ 1%. |

### Depth and Allelic Fraction Thresholds

These thresholds originate from the [Friends of Cancer Research TMB Harmonization Project](pmc.ncbi.nlm.nih.gov/articles/PMC7174078/).

| Argument          | Description                                      |
| ----------------- | ------------------------------------------------ |
| `--vaf 0.05`      | Require a minimum variant allele fraction of 5%. |
| `--minDepth 25`   | Require a minimum total sequencing depth of 25×. |
| `--minAltDepth 3` | Require at least 3 supporting alternate reads.   |

### Quality and Variant-Type Filters

| Argument            | Description                                                            |
| ------------------- | ---------------------------------------------------------------------- |
| `--filterLowQual`   | Exclude variants failing caller or pyTMB-internal quality flags.       |
| `--filterIndels`    | Remove indels, restricting TMB to SNVs only.                           |
| `--filterNonCoding` | Exclude variants outside coding regions.                               |
| `--filterSyn`       | Exclude synonymous variants, retaining only nonsynonymous coding SNVs. |
