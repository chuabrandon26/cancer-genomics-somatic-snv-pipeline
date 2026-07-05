# Cancer Genomics Somatic SNV Pipeline

An automated, containerized bioinformatics pipeline for detecting cancer-specific (somatic) mutations from paired tumor–normal DNA sequencing data, following GATK Best Practices.

## Overview

Cancer is driven by somatic mutations — DNA changes present only in tumor cells, not in the patient's healthy tissue. This project identifies those mutations by comparing tumor and matched-normal whole-exome sequencing data, using an industry-standard workflow: quality control, alignment, duplicate marking, and somatic variant calling with GATK Mutect2. The pipeline is fully automated with Snakemake and packaged in Docker for reproducibility across any machine.

The project demonstrates two complementary workflows:

- **Project 1 — Automated Somatic SNV Pipeline**: Raw FASTQ → aligned BAM → filtered somatic VCF, using BWA-MEM, Samtools, and GATK Mutect2, orchestrated end-to-end with Snakemake.
- **Project 2 — Containerized Multi-Sample QC Engine**: Scales the pipeline to multiple tumor/normal pairs and computes clinically relevant metrics — Variant Allele Frequency (VAF), Tumor Mutational Burden (TMB), and target exon coverage depth — packaged in a Docker container for one-command reproducibility.

## Goal

To build a reproducible, portfolio-quality cancer genomics workflow that mirrors real precision-oncology pipelines used in clinical and research settings, while documenting every step in plain language for transparency and learning.

## Data sources

All input data is public:

- HCC1143 / HCC1143BL (pre-aligned BAM) — [GATK Best Practices somatic-hg38 public bucket](https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38)
- HCC1954 / HCC1954BL (raw FASTQ) — [10x Genomics public WES datasets](https://www.10xgenomics.com/)
- Reference genome GRCh38 and resource files (Panel of Normals, gnomAD, ExAC common variants) — [Broad Institute public reference bucket](https://console.cloud.google.com/storage/browser/gcp-public-data--broad-references/hg38/v0)

## Pipeline workflow

1. **Quality control** — FastQC on raw reads
2. **Alignment** — BWA-MEM against GRCh38
3. **Post-processing** — Samtools sort/index, Picard duplicate marking
4. **Somatic variant calling** — GATK Mutect2 with Panel of Normals and gnomAD filtering
5. **Contamination check** — GetPileupSummaries + CalculateContamination (ExAC common sites)
6. **QC metrics** — VAF, TMB, and exon coverage depth via Mosdepth + pandas
7. **Workflow automation** — Snakemake orchestrates all steps end-to-end
8. **Containerization** — Docker image for full environment reproducibility

## Skills demonstrated

- **Bioinformatics workflow design**: paired tumor/normal somatic variant calling following GATK Best Practices
- **NGS data processing**: FASTQ QC, BWA-MEM alignment, BAM manipulation with Samtools/Picard
- **Variant calling & filtering**: GATK Mutect2, germline/artifact filtering, contamination estimation
- **Workflow automation**: Snakemake for reproducible, dependency-aware pipeline execution
- **Data analysis**: Python (pandas) for calculating VAF, TMB, and coverage metrics from VCF/BAM outputs
- **Containerization & reproducibility**: Docker image packaging for cross-platform, identical execution
- **Environment management**: Conda/Bioconda for tool version control
- **Scientific documentation**: clear, beginner-accessible technical writing translating complex genomics concepts

## Repository structure
