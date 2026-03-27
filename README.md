# AI-Powered Prediction of Psilocybin Production from Microscopy Images of Aspergillus nidulans in Stirred-Tank Reactors
This repository contains a machine learning pipeline for predicting psilocybin production from microscopy images of *Aspergillus nidulans* cultivated in stirred-tank bioreactors. The workflow integrates image segmentation, morphometric feature extraction, and predictive modeling (XGBoost and EfficientNet) to link fungal morphology with product formation dynamics.

## Data
The data underlying this analysis can be found here:  
👉 [link to be added]

## Repository Structure

### 📁 Image segmentation

This folder contains ImageJ macros for processing raw microscopy images and extracting morphological structures.
The raw microscopy images to run segmentation piplines can be found at:  
  - `Dataset/Imaging data/*.tif` 

The workflow consists of the four following steps:

- **1_CFW segmentation.ijm**  
  Performs initial segmentation of fungal structures from microscopy images.

- **2_Artifacts removal.ijm**  
  Removes imaging artifacts and noise to improve segmentation quality.

- **3_Area filter by 500.ijm**  
  Filters segmented objects based on size to exclude irrelevant structures.

- **4_Watershed split.ijm**  
  Applies watershed segmentation to separate connected fungal structures.

#### Fiji plugins required
- MorphoLibJ  
- 3D ImageJ Suite  
- Ridge Detection  
- Tubeness  
- Non-local Means Denoising  

For more information on how to install plugins, please visit:  
https://imagej.net/plugins/

### 📁 Feature extraction

This folder contains scripts for extracting quantitative morphological features from segmented images.
The segmnetation masks to run the feature extraction codes can be found at:  
  - Segmentation data: `Dataset/Segmentation watershed/*.tif` 

- **Morphometry.ijm**  
  Extracts morphometric features of connceted components, including area, perimeter, circularity, Feret diameter, inscribed disk radius, and geodesic elongation. Results are exported as a `.csv` table together with metadata parsed from file names.

- **Erosion survival fraction.ijm**  
  Computes erosion-based survival profiles by iteratively applying disk-shaped erosions to segmented structures and quantifying the remaining foreground area after each step. The output is saved as a `.csv` file containing erosion survival fractions across disk sizes.

- **Degree centrality.ipynb**  
  Computes graph-based degree centrality from segmented binary images by representing foreground pixels as nodes in an 8-connected network. The notebook generates centrality maps and exports degree-centrality distributions as a `.csv`.

### 📁 AI-based prediction of psilocybin

This folder contains machine learning workflows for predicting psilocybin production from images and image-derived morphological features.

- **Data augmentation.ipynb**  
  Performs preprocessing and augmentation of microscopy images to improve model generalization.
  The dataset used in this notebook can be found at:  
  - `Dataset/Imaging data/Cropped_inner_well/*.tif`
  
- **EfficientNet_B3.ipynb**  
  Implements a deep learning approach based on EfficientNet_B3 for predicting psilocybin production directly from image data and biorocess parameters.
  The datasets used in this notebook can be found at:  
  - Imaging data: `Dataset/Imaging data/Cropped_inner_well/*.tif` (or augmented versions of these images obtained via `Data augmentation.ipynb`)  
  - Bioprocess parameters: `Dataset/Bioprocess parameters/Bioprocess parameters.csv`
  
- **XGBoost.ipynb**  
  Applies gradient-boosted decision tree models (XGBoost) using morphological features and biorocess parameters to predict psilocybin production. Includes model training, evaluation, and feature importance analysis (e.g., SHAP).
  The dataset used in this notebook can be found at:  
  - `Dataset/Image-derived features/Merged_df.csv`

#### Python libraries required:
- Python 3.9.19
- numpy 2.0.2
- pandas 2.2.2
- matplotlib 3.9.2
- seaborn 0.13.2
- Pillow 10.4.0
- networkx 3.2.1
- scikit-image 0.24.0
- scikit-learn 1.5.2
- tqdm 4.67.1
- torch 2.4.1
- torchvision 0.19.1
- xgboost 3.2.0
- shap 0.51.0

## Notes

Detailed information and parameter settings are provided as comments within the scripts.
