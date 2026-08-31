# MSI site files

The pipeline supports two MSI detection tools. Each tool has its own param for providing a pre-computed site file; the two are not interchangeable.

| Tool                     | Param                   | When needed                                         |
| ------------------------ | ----------------------- | --------------------------------------------------- |
| MSIsensor2 (default)     | `--msisensor2_scan`     | Optional; primarily for non-human panels            |
| MSIsensor-pro (licensed) | `--msisensor_pro_sites` | Optional; accepts a scan list or a trained baseline |

MSIsensor-pro requires a [license for commercial use](https://github.com/xjtu-omics/msisensor-pro/blob/master/docs/2_License.md). Enable it with `--use_msisensor_pro_licensed`.

# MSIsensor2

MSIsensor2 uses machine learning models by default and does not require a scan file for human genomes (hg38, hg19, b37).

## Selecting an MSIsensor2 Model

Models are available from the [msisensor2 github](https://github.com/niu-lab/msisensor2) for three human genome builds: b37, hg19, and hg38. Select one with `--msisensor2_model_name`. Default is `hg38`.

MSIsensor2 models themselves are underdocumented — see [Anthony & Seoighe 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC11317526/) for a critical review.

## Optional: Generating an MSIsensor2 Scan List

For non-human panels or custom references, supply a pre-computed scan file via `--msisensor2_scan`. The pipeline does not auto-generate one.

1. [Install MSIsensor2](https://github.com/niu-lab/msisensor2?tab=readme-ov-file#install).
2. Download and **_unzip_** the reference genome.

> [!WARNING]
> If the genome is not unzipped, msisensor2 will hang indefinitely.

3. Run the scan command:

```console
msisensor2 scan \
    -d reference.fasta \
    -o reference.msisensor2_scan.list
```

# MSIsensor-pro

> [!IMPORTANT]
> [MSIsensor-pro requires a license for commercial use.](https://github.com/xjtu-omics/msisensor-pro/blob/master/LICENSE)

MSIsensor-pro's `pro` command accepts three kinds of inputs at `-d`. The pipeline routes all of them through `--msisensor_pro_sites`:

1. **(Default) auto-generated scan** — no `--msisensor_pro_sites` supplied; the pipeline runs `msisensor-pro scan` against the reference. `pro` falls back to the `-i` hard threshold (default `0.1`) for every site (see msisensor-pro `polyscan.cpp:250-252`). Fine for initial exploration; less accurate than a trained baseline.
2. **User-supplied scan** — for custom / non-standard panels. You should tune `-i` via `ext.args` to match your panel's characteristics; the pipeline default of `0.1` may not be right.
3. **Trained baseline (recommended for production)** — built from a panel of normals. `pro` uses per-site trained thresholds; the `-i` flag has no effect for trained sites, so leave it alone.

## Generating a scan list

If you want to pre-generate the scan instead of relying on the pipeline:

1. [Install MSIsensor-pro](https://github.com/xjtu-omics/msisensor-pro/blob/master/docs/3_Installation.md).
2. Download and **_unzip_** the reference genome (e.g. from [GIAB](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/)).

> [!WARNING]
> If the genome is not unzipped, msisensor-pro will hang indefinitely.

3. Run the scan command:

```console
msisensor-pro scan \
    -d reference.fasta \
    -o reference.msisensor_pro_sites.list
```

## Generating a baseline (recommended for production)

See the upstream documentation:

- [Best Practices wiki](https://github.com/xjtu-omics/msisensor-pro/wiki/Best-Practices) — recommended workflow for tumor-only MSI detection.
- [`msisensor-pro baseline` usage](https://github.com/xjtu-omics/msisensor-pro/blob/master/docs/4_Usage.md) — command reference and input configuration format.

Briefly: run `msisensor-pro baseline -d <scan.list> -i <configure.txt> -o <baseline_output>`, where `configure.txt` is a text file listing the BAMs of your normal samples (see upstream docs for the exact format). Pass the resulting baseline file to `--msisensor_pro_sites`.

## Tuning `-i`

Pass `-i` through `ext.args` on `MSISENSORPRO_PRO`, for example in your `-c` config:

```groovy
process {
    withName: MSISENSORPRO_PRO {
        ext.args = '-i 0.15'
    }
}
```

This only affects sites whose per-site threshold is `< 0` in the `-d` file. Scan files have `-1` for every site (all sites use `-i`). Trained baselines have positive thresholds per site (so `-i` is ignored except for untrained sites in partial baselines).
