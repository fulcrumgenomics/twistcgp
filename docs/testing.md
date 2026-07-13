# Test Data and the nf-test Suite

The pipeline ships an [nf-test](https://www.nf-test.com/) integration suite that runs
entirely from data committed under [`assets/test-data/`](../assets/test-data), so it is
CI-portable.

Most of the fixtures are tiny, hand-authored, or trimmed from real resources specifically
so the suite stays in the repository. This document records what each custom file is and
how to regenerate it.

## Two coordinate systems

The suite deliberately mixes two references, because it exercises two independent halves of
the pipeline:

- **Alignment and variant calling** run against the nf-core chr21 test reference (`conf/test.config`),
  so those fixtures use `chr21` coordinates. This is the standard nf-core smoke-test genome.
- **Annotation, TMB, and the hotspot fixtures** use real GRCh38 loci on bare-numeric contigs
  (`3`, `7`, `12`, `17`), because they must line up with the trimmed VEP/SnpEff caches
  (`conf/test_annotation.config`). All four hotspots are canonical cancer variants:

  | Gene   | Protein   | Contig | Position (GRCh38) | REF→ALT |
  |--------|-----------|--------|-------------------|---------|
  | BRAF   | V600E     | 7      | 140753336         | A→T     |
  | KRAS   | G12D      | 12     | 25245350          | C→T     |
  | PIK3CA | E545K     | 3      | 179218303         | G→A     |
  | TP53   | R175H     | 17     | 7675088           | C→T     |

## Fixtures and how they were generated

Commands below use `bgzip`/`tabix` from HTSlib and assume you are in `assets/test-data/`.

### `hotspots.vcf.gz`, `hotspots.bed`

The four hotspot sites above, hand-authored as a minimal VCF (REF/ALT only, no genotypes)
and a matching BED of ~1 kb windows around each locus. This is the input to the SnpEff+VEP
annotation subworkflow test.

```console
# hotspots.vcf holds the 4 records; compress + index
bgzip -c hotspots.vcf > hotspots.vcf.gz
tabix -p vcf hotspots.vcf.gz
```

### `cosmic.vcf.gz` (+ `.tbi`)

A **synthetic** COSMIC fixture (`##source=synthetic-cosmic-test-fixture`): the same four
loci carrying `COSV…` IDs, so VEP's `--custom …,COSMIC,vcf,exact,0,ID` has a non-empty,
bgzipped, tabixed target to annotate against. VEP crashes on a record-less custom file, so
this must contain real records at the tested positions.

```console
bgzip -c cosmic.vcf > cosmic.vcf.gz
tabix -p vcf cosmic.vcf.gz
```

### `hotspots.mutect2.vcf`, `hotspots.mutect2.vep.vcf.gz` (+ `.tbi`)

A hand-authored Mutect2-style VCF for the TMB test: the four hotspots with synthetic
`GT:AD:AF:DP` genotype fields and a `POPAF` INFO tag (all four are given a high POPAF so
they survive the population-frequency pre-filter). The `.vep.vcf.gz` is that same file after
being run through the pipeline's Ensembl VEP against the committed cache subset below — it
carries the full `CSQ` annotation and is the direct input to the pyTMB module test.

To regenerate the annotated version, annotate `hotspots.mutect2.vcf` with VEP pointed at
`vep_cache/` (see below), then `bgzip`+`tabix` the result.

### `vep_cache/homo_sapiens/114_GRCh38/`

A ~9 MB **region subset** of the full Ensembl VEP 114 GRCh38 cache. VEP stores its cache as
1 Mb bins (`<contig>/<start>-<end>.gz` plus a `_reg.gz` regulatory sibling); we keep only the
four bins that cover the hotspot loci, plus the top-level `info.txt`:

```
7/140000001-141000000.gz      (BRAF)
12/25000001-26000000.gz       (KRAS)
3/179000001-180000000.gz      (PIK3CA)
17/7000001-8000000.gz         (TP53)
```

To rebuild: download the full `homo_sapiens_vep_114_GRCh38` cache, then copy `info.txt` and
the four `<contig>/<bin>.gz` + `<contig>/<bin>_reg.gz` files that contain each position into
the same directory layout.

### `snpeff_cache/GRCh38.105/`

A ~250-byte **throwaway** SnpEff database built on a tiny fake genome (`genes.gtf` +
`sequences.fa`, one gene on contig `7`). SnpEff output is not consumed downstream — VEP
drives annotation and TMB — so this DB only needs to load and pass records through; the
hotspots fall outside its minimal contigs and are simply not annotated by SnpEff.

```console
# with a snpEff.config registering the GRCh38.105 database on the fake genome
snpEff build -gtf22 -noCheckCds -noCheckProtein GRCh38.105
```

### `targets.bed`, `samplesheet.csv`

- `targets.bed` — the whole chr21 interval (`chr21 0 46709983`) as a BED, matching the
  nf-core chr21 test reference. Some steps (e.g. TMB's `bcftools` pre-filter) require BED,
  not an interval list, so this is committed as BED.
- `samplesheet.csv` — points `test` at the nf-core chr21 paired-end test reads (remote URLs).

> `reference.fa`, `panel.bed`, `panel.intervallist`, the `fastq/` reads, and
> `test_germline_resource.vcf.gz` predate this suite and are reused as-is.

## Running the suite

```console
# full pipeline integration scenarios
nf-test test tests/default.nf.test --profile docker,test

# component tests
nf-test test subworkflows/local/vcf_annotate/tests/main.nf.test --profile docker,test
nf-test test modules/local/tmb/tests/main.nf.test --profile docker,test
```

`--profile docker,test` is required in full: nf-test's `--profile` *replaces* the default
profile set, so both `docker` (containers) and `test` (fixtures/params) must be named.

## Maintaining the snapshot

`tests/default.nf.test.snap` pins content-MD5s of the pipeline's BAM/VCF outputs.

Any change that alters those bytes (for example swapping an
alignment or FASTQ-to-uBAM tool) will legitimately change the snapshot, and it must be
re-recorded:

```console
nf-test test tests/default.nf.test --profile docker,test --update-snapshot
```

Timestamped/volatile reports (FastQC, MultiQC) are excluded from fingerprinting via
[`tests/.nftignore`](../tests/.nftignore) so the snapshot stays reproducible across runs.
