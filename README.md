![logo](https://github.com/chavesejf/pbee/blob/main/figures/toc_page-0001.jpg)

## Overview
PBEE (**P**rotein **B**inding **E**nergy **E**stimator) is an easy-to-use pipeline written in Python3 that use a ML model based on Rosetta descriptors to predict the free energy of binding of protein-protein complexes. More details on PBEE training and validation can be found in our [publication](https://pubs.acs.org/doi/10.1021/acs.jcim.4c01641).

## Requirements

| Package        | Version |
|----------------|---------|
| python         | 3.10    |
| PyRosetta      | 2024    |
| scikit-learn   | 1.3.0   |
| xgboost        | 2.0.1   |
| numpy          | 1.24.4  |
| pandas         | 2.0.3   |

## Google Colab
Before install and run it locally, you can try the online version of PBEE in [Google Colab Notebook](https://colab.research.google.com/drive/1lu1dC0yRltKK_Wp-gF26oHcZSCiHaI8b).

## Download & Install
#### Step 1 - Install Conda (if not already installed)

If Conda is not already installed on your system, follow the instructions below to download and install it:

1. Visit the [Anaconda installation page](https://www.anaconda.com/download/success).
2. Download the Anaconda installer for your operating system.
3. Follow the installation instructions on the page to complete the setup.

After installing Anaconda, you should be able to use `conda` commands in your terminal.

#### Step 2 - Clone the repository

```
git clone https://github.com/chavesejf/PBEE.git
```

#### Step 3 - Create pbee_env in Conda
```
PBEE_PATH=<path_to_pbee_directory>
cd $PBEE_PATH
conda env create -f environment.yml
conda activate pbee_env
```

#### Step 4 - Install PyRosetta in pbee_env
```
pip install pyrosetta-installer
python -c 'import pyrosetta_installer; pyrosetta_installer.install_pyrosetta()'
```

#### Step 5 - Download/Update base models

Download the latest version of the ML models (ex.: v1.0-<file_id>.zip) at the following link:
https://drive.google.com/drive/folders/1tIIaVXekaGzlQ0Z-0NrxoZJbafohHWYg?usp=drive_link

Once the ML models have been downloaded, run the commands below:
```
cd $PBEE_PATH
mkdir $PBEE_PATH/trainedmodels
unzip v1.1-<file_id>.zip -d $PBEE_PATH/trainedmodels
```
## Arguments description

| Argument            | Mandatory | Description |
|---------------------|-----------|-------------|
| -\-ipdb             | Yes       | Input file(s) in the PDB format |
| -\-partner1         | Yes       | Chain ID of the binding partner (e.g.: receptor) |
| -\-partner2         | Yes       | Chain ID of the binding partner (e.g.: ligand) |
| -\-odir             | No        | Output directory |
| -\-mlengine         | No        | Define the machine learning engine |
| -\-ion_dist_cutoff  | No        | Cutoff distance to detect ion(s) close to the protein atoms |          
| -\-frcmod_struct    | No        | Ignores warning messages about structure(s) with gap(s) |
| -\-frcmod_scores    | No        | Ignores warning messages about low-quality descriptors |

## Usage
#### Example 1:
The example below includes the structure of an antibody (HyHEL-63) that binds to lysozyme C (PDB 1XGU) with a binding affinity of -11.28 kcal/mol. In the PDB file, the heavy and light chains of the antibody (ligand) are labeled “A” and “B”, respectively, while lysozyme C (receptor) is labeled “C”. Therefore, the PBEE should be run as follows:

``` 
cd $PBEE_PATH
```
```
python3 pbee.py --ipdb ./tests/pdbs/1xgu.pdb --partner1 AB --partner2 C --odir ./tests
```

The above command will redirect the outputs to `/path/to/pbee/folder/test/pbee_outputs/1xgu`.

## Usage Notes
#### Note 1:
PBEE renames the chains of the complex starting with A, B, C, ... 
Therefore, if you use the HL_W interface, PBEE will rewrite it as follows: AB_C.

#### Note 2:
PBEE supports batch processing of multiple structures using the --ipdb flag. For example:
```
python3 pbee.py --ipdb /path/to/your/files/*.pdb --partner1 AB --partner2 C
```
This command processes all PDB files in the specified directory. However, running PBEE on large datasets can be time-intensive depending on the complexity of the structures. PBEE performs each prediction on a single CPU core, which can further limit throughput for large datasets.
To optimize performance, it is recommended to split the dataset into smaller batches and run PBEE on each batch in parallel, utilizing separate CPU cores for each batch. This approach can significantly accelerate the overall runtime.

## Workflow
```mermaid
flowchart TB
	pdb[/PDB file/] 
	step1[Extracts chains to a new pdb file] 
	step2{Looks for gaps \n in the backbone}
	step3[Checks for ions near \n protein atoms] 
	step4[Remove non-protein atoms] 
	step5["Geometry optimization \n (Rosetta)"] 
	step6["Interface analysis \n (Rosetta)"] 
	step7[SL engine]
	result[dGbind]
	ends[End process]
	
	subgraph B[ ]
	step5 --> step6 --> step7
	end 
	
	subgraph A[ ]
	step1 --> step2
	step2 --> |Yes| ends
	step2 --> |No| step3
	step3 --> step4
	end 
	
	pdb -.- step1
	step4 -.-> step5
	step7 -.-> result
``` 

## Description of the Rosetta XML script

The following is an example of a Rosetta XML script used in the PBEE. In general, the script outlines a pipeline for analyzing and manipulating protein structures, utilizing a variety of scoring functions, residue selectors, simple metrics, filters, movers, and protocols. In this context, the script aims to assess and refine interactions between two protein chains, focusing on interaction energy and structural features. Furthermore, the script includes steps for minimization, energy metric calculation, and structure selection based on specific filters. 

```xml
<ROSETTASCRIPTS>
<SCOREFXNS>
	<ScoreFunction name="beta" weights="beta_nov16"/>
</SCOREFXNS>
<RESIDUE_SELECTORS>
	<Chain name="partner1" chains="AB"/>
	<Chain name="partner2" chains="C"/>
</RESIDUE_SELECTORS>
<TASKOPERATIONS>
	<InitializeFromCommandline name="init"/>
</TASKOPERATIONS>
<SIMPLE_METRICS>
	<InteractionEnergyMetric name="ie" residue_selector="partner1" residue_selector2="partner2" scorefxn="beta"/>
</SIMPLE_METRICS>
<FILTERS>
	<ShapeComplementarity name="sc" residue_selector1="partner1" residue_selector2="partner2" confidence="0"/>
	<ContactMolecularSurface name="cms" distance_weight="0.5" target_selector="partner1" binder_selector="partner2" confidence="0"/>
	<InterfaceHoles name="holes" jump="1" confidence="0"/>
	<Ddg name="ddg_filter1" scorefxn="beta" jump="1" chain_num="2" repeats="1" repack="0" repack_bound="0" repack_unbound="0" threshold="99999" confidence="0"/>
</FILTERS>
<MOVERS>
	<MinMover name="min1" scorefxn="beta" jump="1" max_iter="50000" tolerance="0.0001" cartesian="0" bb="0" chi="1" bb_task_operations="init" chi_task_operations="init"/>
	<MinMover name="min2" scorefxn="beta" jump="1" max_iter="50000" tolerance="0.0001" cartesian="0" bb="1" chi="1" bb_task_operations="init" chi_task_operations="init"/>
	<InterfaceAnalyzerMover name="ifa" scorefxn="beta" interface="AB_C" packstat="1" interface_sc="1" tracer="1" scorefile_reporting_prefix="ifa"/>
	<RunSimpleMetrics name="iesum" metrics="ie"/>
</MOVERS>
<PROTOCOLS>
	<Add mover_name="min1"/>
	<Add mover_name="min2"/>
	<Add mover_name="iesum"/>
	<Add mover_name="ifa"/>
	<Add filter_name="ddg_filter1"/>
	<Add filter_name="cms"/>
	<Add filter_name="sc"/>
	<Add filter_name="holes"/>
</PROTOCOLS>
</ROSETTASCRIPTS>
```

1. The script begins by defining the **scoring functions** to be used, which weigh different energetic terms concerning protein interactions;
2. Subsequently, **residue selectors** are set up to identify the protein chains of interest, labeled as "**partner1**" and "**partner2**." 
3. Task operations are also defined to initialize parameters from the command line. The next script section introduces **simple metrics** that evaluate specific aspects of the protein structure, such as interaction energy between selected residues in the "partner1" and "partner2" chains. 
4. In the **filters** section, a series of filters are defined to assess structural and energetic properties of interactions. These filters encompass calculations of shape complementarity, molecular surface contacts, interface holes, and changes in free energy (ddG). 
5. **Movers** are defined to carry out minimization and interface analysis. This includes minimization with varying parameters and levels of detail, as well as **interface analysis** to evaluate features such as packing and hydrogen bonding. Lastly, protocols are constructed using the defined movers and filters. 
6. The movers and filters are added in a specific sequence to perform desired analysis and refinement steps. This encompasses minimization, metric calculation, interface analysis, and the application of filters to select structures meeting predetermined criteria.

In summary, the XML script represents a detailed plan for protein structure analysis and manipulation using Rosetta. It outlines a series of steps aimed at evaluating protein chain interactions and improving structure quality.

## Docker

You can also run the model using Docker:

1. Build the Docker image locally:

   ```bash
   docker build -t pbee .
   ```

   Or pull the pre-built image from Docker Hub:

   ```bash
   docker pull cford38/pbee:latest
   ```

2. Run the Docker container:

   ```bash
   docker run --gpus all --rm --name pbee -it pbee /bin/bash
   # docker run --gpus all --rm --name pbee -it cford38/pbee:latest /bin/bash
   ```
> [!NOTE]
> This image does not include all of the model weights, which will be downloaded the first time you run PBEE inside in the container.


## Citation
If you use our code or ML model, please cite our work:
```
@article{Chaves2025,
  title = {Estimating Absolute Protein–Protein Binding Free Energies by a Super Learner Model},
  ISSN = {1549-960X},
  url = {http://dx.doi.org/10.1021/acs.jcim.4c01641},
  DOI = {10.1021/acs.jcim.4c01641},
  journal = {Journal of Chemical Information and Modeling},
  publisher = {American Chemical Society (ACS)},
  author = {Chaves,  Elton J. F. and Sartori,  João and Santos,  Whendel M. and Cruz,  Carlos H. B. and Mhrous,  Emmanuel N. and Nacimento-Filho,  Manassés F. and Ferraz,  Matheus V. F. and Lins,  Roberto D.},
  year = {2025},
  month = feb 
}
```
