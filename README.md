# AI-Powered Prediction of Psilocybin Production from Microscopy Images of Aspergillus nidulans in Stirred-Tank Reactors
This repository contains a machine learning pipeline for predicting psilocybin production from microscopy images of *Aspergillus nidulans* cultivated in stirred-tank bioreactors. The workflow integrates image segmentation, morphometric feature extraction, and predictive modeling (XGBoost and EfficientNet) to link fungal morphology with product formation dynamics.

## Data
The data underlying this analysis can be found here:  
👉 [link to be added]

## Repository Structure

### 📁 Image segmentation

This folder contains ImageJ macros for processing raw microscopy images and extracting morphological structures.

The workflow consists of the following steps:

- **1_CFW segmentation.ijm**  
  Performs initial segmentation of fungal structures from microscopy images.

- **2_Artifacts removal.ijm**  
  Removes imaging artifacts and noise to improve segmentation quality.

- **3_Area filter by 500.ijm**  
  Filters segmented objects based on size to exclude irrelevant structures.

- **4_Watershed split.ijm**  
  Applies watershed segmentation to separate connected fungal structures.

## How to run the code
To install ImageJ/Fiji, please visit:  
https://imagej.net/ij/download.html

To open a macro:
- Use **File → Open**, or  
- **Plugins → Macros → Edit**, or  
- Drag and drop the `.ijm` file onto the ImageJ/Fiji window  

## Required plugins
Please make sure the following plugins are installed:
- MorphoLibJ  
- 3D ImageJ Suite  
- Ridge Detection  
- Tubeness  
- Non-local Means Denoising  

For more information on how to install plugins, please visit:  
https://imagej.net/plugins/


## Notes

Detailed information and parameter settings are provided as comments within the scripts.


### 📁 Feature extraction

This folder contains scripts for extracting quantitative morphological features from segmented images.

*(you can expand this later)*

---

### 📁 AI-based prediction of psilocybin

This folder includes machine learning models and notebooks for predicting psilocybin production based on extracted features.

- Data preprocessing and augmentation  
- Model training (XGBoost, EfficientNet)  
- Evaluation and prediction

*(we can refine this together later)*
