# BrainMesh

**A MATLAB graphical user interface (GUI) for rendering 3D mouse brain structures**


![alt text](https://github.com/yaoyao-hao/BrainMesh/blob/master/docs/media/spin.gif)


## Getting Started
Run ```BrainMesh.m``` in MATLAB (developed in R2019)

## Highlighted Features
* Select Allen brain structures direct from a tree component (GUI)
* Render unilateral (only left or right) or bilateral part of a brain structure
* Support custom data points, slice images and 3D structures
* Export 3D images and/or videos w/ spining against x, y or z axis

## Toturial
* Following the **3 steps** in the main GUI to render brain structures you want.
  - ![alt text](https://github.com/yaoyao-hao/BrainMesh/blob/master/docs/media/maingui.png)

  - **STEP 1/3**: Select brain structure in the tree component (left side) and click 'add>>' button to add the selected brain structure into the table on the right side; Add as many structures as you want; Press 'ctrl' key to select multiple brain structures. *Tip:* the same structure could be added twice (with a warning), so that you can render it with different parameters (e.g., color, left/right part, etc.).
  - **STEP 2/3**: For each brain in the Table, click the color cell to pick a color for that brain structure; Change alpha value to adjust the transparency (0-totally transparent, 1-opaque); Chose the left or right or both side of the structure to be rendered by clicking the corresponding check box.
  - *STEP 2/3 (optional)*: You can also load you own data points (.mat file, nx3 matrix), slice image (aligned to Allen brain atlas CCF), and your own 3d structure (.obj file or .mat file with v (verticies) and F (Faces) field) to the Table. BrainMesh will render them with the brain structures you selected in the same scene. see example data in foleder './Data/example_data/'
  - **STEP 3/3**: Click the 'Start Rendering..' button to render all the items in the table in a new window (rendering). This will take a few minutes since the BrainMesh will first download the structure from Allen Institure and load them into the workspace to render. *Tip:* click the 'Download all structures' button at the left bottom will download all the 840 Allen brain structures (227 MB) to your computer. This will accelerate the speed for rendering.
  
* **Customize** the scene in the rendering window and **export** image or video with spining
  - ![alt text](https://github.com/yaoyao-hao/BrainMesh/blob/master/docs/media/toolbar.png)
  - using the camera toolbar to custom the scene, as shwon above
  - using the spin x, y, z toolbar to spin the rendered brain a circle
  - using the export video toolbar to export a video with customized parameter
  - select menu->File->Save to save the current scene to an image.

## Citation

BrainMesh: A Matlab GUI for rendering 3D mouse brain structures (2020) https://github.com/Yaoyao-Hao/BrainMesh/

## Contribution
Feel free to pull a request If you want to contribute code to this repository, or leave your messages (bugs, comments, etc.) in the Issues page.

## Similar Tools
* In R: cocoframer https://github.com/AllenInstitute/cocoframer
* In python: BrainRender https://github.com/BrancoLab/BrainRender

## Reference
* Brain structure mesh data from Allen Institute: http://download.alleninstitute.org/informatics-archive/current-release/mouse_ccf/annotation/ccf_2017/structure_meshes/
* Brain structure ontology from: http://api.brain-map.org/api/v2/data/query.csv?criteria=model::Structure,rma::criteria,[ontology_id$eq1],rma::options[order$eq%27structures.graph_order%27][num_rows$eqall]
* Obj file reader from: https://www.mathworks.com/matlabcentral/fileexchange/10223-loadawobj 
* rgb2hex and hex2rgb from: https://www.mathworks.com/matlabcentral/fileexchange/46289-rgb2hex-and-hex2rgb
