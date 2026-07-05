# ============================================================================
# Single-pair pipeline for HCC1954: raw FASTQ -> final filtered VCF.
# This file is written in the Snakemake language (which is built on Python).
# ============================================================================
configfile: "config.yaml"

import glob

REF        = config["reference"]
GNOMAD     = config["gnomad"]
PON        = config["pon"]
COMMON     = config["common_biallelic"]
TUMOR      = config["tumor_sample"]
NORMAL     = config["normal_sample"]
PAIR       = config["pair_name"]
FASTQ_DIRS = config["samples_fastq"]
MUTECT_MEM       = config["mutect_mem"]
PAIRHMM_THREADS  = config["pairhmm_threads"]

# Find the interleaved genomic read files (read-RA_*) for one sample.
def ra_files(wildcards):
    folder = FASTQ_DIRS[wildcards.sample]
    return sorted(glob.glob(f"{folder}/read-RA_*.fastq.gz"))

# rule all names the final file we want; Snakemake works backward from here.
rule all:
    input:
        f"results/vcf/{PAIR}.filtered.vcf.gz"

# Align one sample's interleaved reads, then sort and index the result.
rule bwa_align:
    input:
        reads = ra_files,
        ref   = REF
    output:
        "results/bam/{sample}.sorted.bam"
    threads: 4
    shell:
        r"""
        R1="results/bam/{wildcards.sample}.R1.fastq"
        R2="results/bam/{wildcards.sample}.R2.fastq"
        zcat {input.reads} | paste - - - - | awk -F'\t' -v r1="$R1" -v r2="$R2" '
          NR % 2 == 1 {{ gsub(/\t/, "\n"); print > r1 }}
          NR % 2 == 0 {{ gsub(/\t/, "\n"); print > r2 }}
        '
        bwa mem -M -t {threads} \
          -R "@RG\tID:{wildcards.sample}\tSM:{wildcards.sample}\tPL:ILLUMINA\tLB:{wildcards.sample}\tPU:{wildcards.sample}" \
          {input.ref} "$R1" "$R2" \
          | samtools sort -@ 2 -m 512M -o {output} -
        samtools index {output}
        rm -f "$R1" "$R2"
        """

# Flag duplicate reads with Picard.
rule mark_duplicates:
    input:
        "results/bam/{sample}.sorted.bam"
    output:
        bam     = "results/bam/{sample}.markdup.bam",
        metrics = "results/bam/{sample}.dup_metrics.txt"
    shell:
        r"""
        picard MarkDuplicates INPUT={input} OUTPUT={output.bam} METRICS_FILE={output.metrics}
        samtools index {output.bam}
        """

# Learn and apply base quality score recalibration.
rule bqsr:
    input:
        bam   = "results/bam/{sample}.markdup.bam",
        ref   = REF,
        known = GNOMAD
    output:
        table = "results/bam/{sample}.recal.table",
        bam   = "results/bam/{sample}.recal.bam"
    shell:
        r"""
        gatk BaseRecalibrator -I {input.bam} -R {input.ref} --known-sites {input.known} -O {output.table}
        gatk ApplyBQSR -I {input.bam} -R {input.ref} --bqsr-recal-file {output.table} -O {output.bam}
        """

# Call candidate somatic mutations from the tumor and normal together.
rule mutect2:
    input:
        tumor  = f"results/bam/{TUMOR}.recal.bam",
        normal = f"results/bam/{NORMAL}.recal.bam",
        ref    = REF,
        gnomad = GNOMAD,
        pon    = PON
    params:
        normal = NORMAL,
        mem    = MUTECT_MEM,
        pairhmm_threads = PAIRHMM_THREADS
    output:
        vcf  = f"results/vcf/{PAIR}.unfiltered.vcf.gz",
        f1r2 = f"results/vcf/{PAIR}.f1r2.tar.gz"
    shell:
        r"""
        gatk --java-options "{params.mem}" Mutect2 -R {input.ref} -I {input.tumor} -I {input.normal} -normal {params.normal} \
          --germline-resource {input.gnomad} --panel-of-normals {input.pon} \
          --native-pair-hmm-threads {params.pairhmm_threads} \
          --f1r2-tar-gz {output.f1r2} -O {output.vcf}
        """

# Model the read-orientation artifact.
rule orientation_model:
    input:
        f"results/vcf/{PAIR}.f1r2.tar.gz"
    output:
        f"results/vcf/{PAIR}.read-orientation-model.tar.gz"
    shell:
        "gatk LearnReadOrientationModel -I {input} -O {output}"

# Summarize common-variant pileups (used to estimate contamination).
rule pileup_summaries:
    input:
        tumor  = f"results/bam/{TUMOR}.recal.bam",
        common = COMMON
    output:
        f"results/vcf/{PAIR}.pileups.table"
    shell:
        "gatk GetPileupSummaries -I {input.tumor} -V {input.common} -L {input.common} -O {output}"

# Turn the pileup summaries into a contamination estimate.
rule contamination:
    input:
        f"results/vcf/{PAIR}.pileups.table"
    output:
        cont = f"results/vcf/{PAIR}.contamination.table",
        seg  = f"results/vcf/{PAIR}.segments.table"
    shell:
        "gatk CalculateContamination -I {input} -tumor-segmentation {output.seg} -O {output.cont}"

# Apply all filters to produce the final PASS/fail VCF.
rule filter_calls:
    input:
        vcf  = f"results/vcf/{PAIR}.unfiltered.vcf.gz",
        ref  = REF,
        cont = f"results/vcf/{PAIR}.contamination.table",
        seg  = f"results/vcf/{PAIR}.segments.table",
        ob   = f"results/vcf/{PAIR}.read-orientation-model.tar.gz"
    output:
        f"results/vcf/{PAIR}.filtered.vcf.gz"
    shell:
        r"""
        gatk FilterMutectCalls -R {input.ref} -V {input.vcf} \
          --contamination-table {input.cont} --tumor-segmentation {input.seg} \
          --ob-priors {input.ob} -O {output}
        """
