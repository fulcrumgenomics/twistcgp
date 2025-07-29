MSIsensor2 is the default microsattelite instability detection tool used in the pipeline.
MSIsensor-pro is available for [MSIsensor-pro licensed users](https://github.com/xjtu-omics/msisensor-pro/blob/master/LICENSE).

# Steps to Generate a MSIsensor2 Scan List

1. [Install MSIsensor2](https://github.com/niu-lab/msisensor2?tab=readme-ov-file#install)

2. Download and ***unzip*** the reference genome from GIAB, [fasta.gz link](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz).

3. Run the MSIsensor2 scan command:

```console
msisensor2 scan \
        -d GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta \
        -o GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.msisensor2_scan.list
```

# Steps to Generate a MSIsensor-pro Scan List

> [!IMPORTANT]
> [MSIsensor-pro requires a license for commercial use.](https://github.com/xjtu-omics/msisensor-pro/blob/master/LICENSE)


1. [Install MSIsensor-pro](https://github.com/xjtu-omics/msisensor-pro/blob/master/docs/3_Installation.md)

2. Download and ***unzip*** the reference genome from GIAB, [fasta.gz link](https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz).

3. Run the MSIsensor-pro scan command:

```console
msisensor-pro scan \
        -d GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta \
        -o GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.msisensor2_scan.list
```
