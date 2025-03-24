FROM rosettacommons/rosetta:jupyter

LABEL authors="Colby T. Ford <colby@tuple.xyz>"
ENV DEBIAN_FRONTEND=noninteractive
USER root

## Set working directory
RUN mkdir -p /software/PBEE
WORKDIR /software/PBEE

## Clone PBEE repository
RUN git clone https://github.com/chavesejf/PBEE.git /software/PBEE
WORKDIR /software/PBEE

## Create conda environment
RUN conda env create -f /software/PBEE/environment.yml

## Install PyRosetta in environment
RUN conda install -n pbee_env -c https://conda.rosettacommons.org -y pyrosetta

## Automatically activate conda environment
RUN echo "source activate pbee_env" >> /etc/profile.d/conda.sh && \
    echo "source /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate pbee_env" >> ~/.bashrc