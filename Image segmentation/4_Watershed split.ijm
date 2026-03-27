setBatchMode("true");
setBatchMode("hide");
setOption("BlackBackground", true);
setOption("ExpandableArrays", true);

//Parameters
prm_area=300;
prm_mfd=500;
ResXY=3.7744;
prm_opn=2;
prm_cls=2;
prm_area_seed=1000;

// Define the root directory
rootDir = ".../Segmentation/Artifacts removed/Area over 500/";
outputDir = ".../Segmentation watershed/";
File.makeDirectory(outputDir);

// Get the list of the CFW images
list_CFW = getFileList(rootDir);

for (img = 0; img < list_CFW.length; img++) {	
	
	open(rootDir + list_CFW[img]);	
	rename("Original");

	// MFD filter
	run("Duplicate...", "title=Microcolony");
	run("Shape Filter", "feret_diameter="+prm_mfd+"-Infinity draw_holes black_background");

	getStatistics(area, mean, min, max, std, histogram);
	
	// In case of large objects
	if (max==255) {
		
		// Get Microcolony-Individual
		imageCalculator("Subtract create", "Original","Microcolony");
		rename("Microcolony-Individual");
		
		//Sead estimation in 2D
		selectImage("Microcolony");
		run("Morphological Filters", "operation=Opening element=Disk radius=prm_opn");	
		run("Morphological Filters", "operation=Closing element=Disk radius=prm_cls");
		run("Shape Filter", "area="+prm_area_seed+"-Infinity draw_holes black_background");
		rename("seeds2D");

		// In case of lost objects through opening!
		selectImage("Microcolony");
		run("Connected Components Labeling", "connectivity=8 type=[16 bits]");
		selectImage("seeds2D");
		run("Duplicate...", "title=seeds2D-thresholded");
		setThreshold(1.0000, 1.0000E+30);
		run("Convert to Mask");
		run("Intensity Measurements 2D/3D", "input=seeds2D-thresholded labels=Microcolony-lbl mean max min");
		Table.rename("seeds2D-thresholded-intensity-measurements", "Results");
		
		selectImage("Microcolony-lbl");
		for (i = 0; i < nResults; i++) {
			max = getResult("Max", i);
			if (max == 255) {
				lbl=i+1;
				run("Replace/Remove Label(s)", "label(s)="+lbl+" final=0");		
			}
		}
		rename("Lost_objects");
		setThreshold(1.0000, 1.0000E+30);
		run("Convert to Mask");		
		close("Results");
		close("seeds2D-thresholded");

		//Splitting
		run("3D Watershed Split", "binary=Microcolony seeds=seeds2D radius=2"); //Split 16-bit
		Stack.setXUnit("micron");
		run("Properties...", "pixel_width="+ResXY+" pixel_height="+ResXY+" voxel_depth=1");	
		
		setThreshold(1.0000, 1.000E+30);
		run("Convert to Mask", "background=Dark black");	
		
		imageCalculator("Add", "Split","Microcolony-Individual");
		imageCalculator("Add", "Split","Lost_objects");

		// Save Segmentation & Close
		selectImage("Split");
		run("Shape Filter", "area="+prm_area+"-Infinity draw_holes black_background");
		saveAs("Tiff", outputDir + substring(list_CFW[img], 0, lastIndexOf(list_CFW[img], ".tif")) + "_Splitted");	
		close("Results");
		close("*");	
	}
	else {
		// Save Segmentation & Close
		selectImage("Original");
		saveAs("Tiff", outputDir + substring(list_CFW[img], 0, lastIndexOf(list_CFW[img], ".tif")) + "_Original");	
		close("Results");
		close("*");			
	}

}
