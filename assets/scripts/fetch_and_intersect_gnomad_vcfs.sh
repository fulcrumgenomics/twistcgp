#!/usr/bin/env bash
set -euo pipefail

# ========= USER SETTINGS =========
TARGET_BED="assets/Targeted_Twist_OncoProfilerDNA_Ver2_TE-96008936_hg38_v2.02.bed"

# Build list of chromosome VCF URLs
EXOME_FILES=()
for CHR in {1..22} X Y; do
    EXOME_FILES+=("https://storage.googleapis.com/gcp-public-data--gnomad/release/4.1/vcf/exomes/gnomad.exomes.v4.1.sites.chr${CHR}.vcf.bgz")
done

# Directory to store intermediate and output files
WORK_DIR="assets/gnomad_vcf_processing"
mkdir -p "$WORK_DIR"

# Final merged output
MERGED_OUTPUT="$WORK_DIR/all_chromosomes.intersect.vcf.bgz"
TEMP_MERGED="$WORK_DIR/temp_merged.vcf.bgz"

echo "Using target BED: $TARGET_BED"
echo "Output directory: $WORK_DIR"

# ========= PROCESS CHROMOSOMES =========
for VCF_URL in "${EXOME_FILES[@]}"; do
    VCF_FILE="$WORK_DIR/$(basename "$VCF_URL")"
    TBI_URL="${VCF_URL}.tbi"
    TBI_FILE="${VCF_FILE}.tbi"

    # ---- Download VCF and index if missing ----
    if [ ! -f "$VCF_FILE" ]; then
        echo "Downloading $VCF_URL..."
        wget -q -O "$VCF_FILE" "$VCF_URL"
    else
        echo "VCF already exists, skipping download."
    fi

    if [ ! -f "$TBI_FILE" ]; then
        echo "Downloading $TBI_URL..."
        wget -q -O "$TBI_FILE" "$TBI_URL"
    else
        echo "Index already exists, skipping download."
    fi

    # ---- Intersect with BED ----
    CHR_NAME=$(basename "$VCF_FILE" .vcf.bgz)
    INTERSECT_FILE="$WORK_DIR/${CHR_NAME}.intersect.vcf.bgz"

    if [ ! -f "$INTERSECT_FILE" ]; then
        echo "Intersecting $(basename "$VCF_FILE") with $TARGET_BED..."
        bcftools view -R "$TARGET_BED" "$VCF_FILE" -Oz -o "$INTERSECT_FILE"
        tabix -p vcf "$INTERSECT_FILE"
    else
        echo "Intersection for $(basename "$VCF_FILE") already exists, skipping."
    fi

    # ---- Delete raw VCF to save space ----
    echo "Deleting $VCF_FILE and its index..."
    rm -f "$VCF_FILE" "$TBI_FILE"

    echo "Done with $(basename "$VCF_FILE")"
done

# ========= MERGE INTERSECTED FILES =========
echo "Merging intersected files..."
INTERSECT_FILES=("$WORK_DIR"/*.intersect.vcf.bgz)

if [ ${#INTERSECT_FILES[@]} -eq 0 ]; then
    echo "No intersected files found. Exiting."
    exit 1
fi

if [ ! -f "$MERGED_OUTPUT" ]; then
    echo "  - Concatenating..."
    bcftools concat -a -O z -o "$TEMP_MERGED" "${INTERSECT_FILES[@]}"

    echo "  - Sorting..."
    bcftools sort -O z -o "$MERGED_OUTPUT" "$TEMP_MERGED"

    echo "  - Indexing..."
    tabix -p vcf "$MERGED_OUTPUT"

    echo "  - Cleaning temporary merged file..."
    rm -f "$TEMP_MERGED"
else
    echo "  - Merged output already exists, skipping merge."
fi

# ========= CLEANUP =========
echo "Cleaning intermediate intersect files..."
rm -f "${INTERSECT_FILES[@]}"

echo "All chromosomes processed and merged into:"
echo "$MERGED_OUTPUT"
