# BrainMesh

A Matlab graphical user interface (GUI) for rendering 3D mouse brain structures

![alt text](https://github.com/yaoyao-hao/BrainMesh/blob/master/docs/media/maingui.png)

![alt text](https://github.com/yaoyao-hao/BrainMesh/blob/master/docs/media/spin.gif)

## Getting Started
Run ```BrainMesh.m``` in MATLAB (R2019)
## Highlighted Features
* Select Allen brain structures direct from a tree component
* Render unilateral (only left or right) or bilateral part of a brain structure
* Support custom data points, slice images and 3D structures
* Export 3D images and/or videos w/ spining against x, y or z axis
## Toturial
* Following the 3 steps in the main GUI to render brain structures you want.
** STEP 1/3: Select brain structure(s) and add to the right Table
**
**
![alt text](https://github.com/yaoyao-hao/BrainMesh/blob/master/2020-02-03_17-37-59.gif)

## Citation
BrainMesh: A Matlab GUI for rendering 3D mouse brain structures (2020) https://github.com/yaoyao-hao/BrainMesh/
## Contribution
Feel free to pull a request If you want to contribute code to this repository, or leave messages (bugs, comments, etc.) in the Issues page.
## Similar Tools
* In R: cocoframer https://github.com/AllenInstitute/cocoframer
* In python: BrainRender https://github.com/BrancoLab/BrainRender
## Reference
* Brain structure mesh data from Allen Institute: http://download.alleninstitute.org/informatics-archive/current-release/mouse_ccf/annotation/ccf_2017/structure_meshes/
* Brain structure ontology from: http://api.brain-map.org/api/v2/data/query.csv?criteria=model::Structure,rma::criteria,[ontology_id$eq1],rma::options[order$eq%27structures.graph_order%27][num_rows$eqall]
* Obj file reader from: https://www.mathworks.com/matlabcentral/fileexchange/10223-loadawobj 
* rgb2hex and hex2rgb from: https://www.mathworks.com/matlabcentral/fileexchange/46289-rgb2hex-and-hex2rgb
