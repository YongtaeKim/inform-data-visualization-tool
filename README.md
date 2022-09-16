# inform-data-visualization-tool
Visualizing output data from inForm(WSI analysis software) with Julia Pluto notebook.

## Instruction
1. Install the required packages with the following command.
```
julia> ] add Pkg, FileIO, Markdown, InteractiveUtils, DataFrames, CSV, Plots, Images, PlutoUI, ImageDraw, Colors, WebIO, Dates, PlotlyJS
```
2. Download ```Visualize.jl``` and the sample dataset.
3. Launch Pluto notebook and open the ```Visualize.jl```.
4. Enter the path to the sample dataset (eg. ~/Downloads/sample_dataset/27_Scan1/) in the Pluto notebook.
5. Notebook should be loaded with the sample data.

---

## Etc
### H-Score.jl
- View H-Score under user setting with Pluto notebook.

### Filter-and-Merge.jl
- Command line script that merges multiple region data into single file with certain cell data filtered out.
