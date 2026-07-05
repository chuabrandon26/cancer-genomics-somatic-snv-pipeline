# Start from a small Linux image that already includes conda.
FROM continuumio/miniconda3:latest

# Set the working folder inside the container.
WORKDIR /pipeline

# Copy the tool list into the image first (so this slow step is cached and reused).
COPY environment.yml /pipeline/environment.yml

# Build the conda environment from that list, then clean up to keep the image small.
RUN conda env create -f environment.yml && conda clean -a -y

# Put the environment's programs on the PATH so they are found automatically.
ENV PATH=/opt/conda/envs/cancer_genomics/bin:$PATH

# Copy our workflow files into the image.
COPY Snakefile Snakefile_multi config.yaml config_multi.yaml /pipeline/

# By default, run the scaled workflow when the container starts.
# The user can override these arguments on the command line.
ENTRYPOINT ["snakemake"]
CMD ["-s", "Snakefile_multi", "--cores", "4"]
