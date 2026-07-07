# Cancer Genomics Somatic SNV Pipeline

An automated, containerized bioinformatics pipeline for detecting cancer-specific (somatic) mutations from paired tumor–normal DNA sequencing data, following GATK Best Practices.
This project uses datasets from Breast Cancer. Specifically,  two tumor/normal pairs of the HCC1143 and HCC1954 cell lines, which are well-known breast cancer cell lines

## Overview

Cancer is driven by somatic mutations, DNA changes present only in tumor cells, not in the patient's healthy tissue. This project identifies those mutations by comparing tumor and matched-normal whole-exome sequencing data, using an industry-standard workflow: quality control, alignment, duplicate marking, and somatic variant calling with GATK Mutect2. The pipeline is fully automated with Snakemake and packaged in Docker for reproducibility across any machine.

The project demonstrates two complementary workflows:

- **Project 1: Automated Somatic SNV Pipeline**: Raw FASTQ → aligned BAM → filtered somatic VCF, using BWA-MEM, Samtools, and GATK Mutect2, orchestrated end-to-end with Snakemake.
- **Project 2: Containerized Multi-Sample QC Engine**: Scales the pipeline to multiple tumor/normal pairs and computes clinically relevant metrics: Variant Allele Frequency (VAF), Tumor Mutational Burden (TMB), and target exon coverage depth — packaged in a Docker container for one-command reproducibility.

## Goal

To build a reproducible cancer genomics workflow that mirrors real precision-oncology pipelines used in clinical and research settings.
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

    ├── Snakefile                              # Single-sample pipeline rules
    ├── Snakefile_multi                        # Multi-sample scaled pipeline
    ├── config / config_multi                  # Pipeline configuration files
    ├── Dockerfile                              # Container build specification
    ├── environment                             # Conda environment definition
    ├── cancer_genomics_pipeline_report.ipynb   # Full documented walkthrough
    └── results/                                # Final VCFs, coverage tables, VAF/TMB summaries


## Environment & reproducibility notes

This pipeline was developed and executed using WSL2 with a Conda (Bioconda) environment, as the specialized tools (BWA, Samtools, GATK4, Snakemake) require a Linux environment. The included `Dockerfile` and `environment.yml` define the exact reproducible environment; due to local hardware constraints, the Docker image build/run was validated conceptually and documented in detail rather than executed on this machine, but the container is designed to run identically on any system with Docker installed.

## How to run

```bash
# Create environment
conda create -y -n cancergenomics -c conda-forge -c bioconda \
  python=3.10 bwa samtools htslib gatk4 snakemake-minimal picard fastqc mosdepth pandas matplotlib
conda activate cancergenomics

# Run pipeline
snakemake --cores 4

# Or via Docker (recommended for full reproducibility)
docker build -t cancer-genomics-pipeline .
docker run -v $(pwd)/results:/app/results cancer-genomics-pipeline
```






