setBatchMode("true");
setBatchMode("hide");

// Define the root directory
rootDir = ".../Segmentation/Artifacts removed/";
outputDir = rootDir + "Area over 500/";
File.makeDirectory(outputDir);

// Get the list of the CFW images
list_CFW = getFileList(rootDir);
//Array.show(list_CFW);

for (img = 0; img < list_CFW.length-1; img++) {	
	
	open(rootDir + list_CFW[img]);	
	Stack.setXUnit("micron");
	run("Properties...", "pixel_width=3.77442 pixel_height=3.77442 voxel_depth=1");
	// Note: voxel_depth=1 to measure area and not volume!!!
	run("Particle Analyser", "  min=500 max=Infinity surface_resampling=2 show_particle surface=Gradient split=0.000 volume_resampling=2");

	setOption("BlackBackground", true);
	setThreshold(1.0000, 1.0000E+32);
	run("Convert to Mask");

	// Save Segmentation & Close
	saveAs("Tiff", outputDir + list_CFW[img]);	
	close("*");
}