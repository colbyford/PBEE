FROM rosettacommons/rosetta:jupyter

LABEL authors="Colby T. Ford <colby@tuple.xyz>"

USER root

## Install system requirements
# RUN apt update && \
#     apt-get install -y --reinstall \
#         ca-certificates \
#         make && \
#     apt install -y \
#         build-essential \
#         git \
#         wget \
#         gcc \
#         g++

## Set working directory
RUN mkdir -p /software/PBEE
WORKDIR /software/PBEE

## Clone PBEE repository
RUN git clone https://github.com/chavesejf/PBEE.git /software/PBEE
WORKDIR /software/PBEE

## Create conda environment
RUN conda env create -f environment.yml

## Install PyRosetta from environment
RUN /opt/conda/envs/pbee_env/bin/python3 -m pip install pyrosetta_installer && \
    /opt/conda/envs/pbee_env/bin/python3 -c 'import pyrosetta_installer; pyrosetta_installer.install_pyrosetta()'

## Automatically activate conda environment
RUN echo "source activate pbee_env" >> /etc/profile.d/conda.sh && \
    echo "source /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate pbee_env" >> ~/.bashrc
