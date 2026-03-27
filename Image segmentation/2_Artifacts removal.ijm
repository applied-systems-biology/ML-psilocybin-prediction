setBatchMode("true");
setBatchMode("hide");
setOption("BlackBackground", true);
setOption("ExpandableArrays", true);

// Define the root directory
rootDir = ".../Imaging data/";
rootDir_seg = ".../Segmentation/";
outputDir = rootDir_seg + "Artifacts removed/";
File.makeDirectory(outputDir);

// Get the list of the CFW images
list_Imgs = getFileList(rootDir);

list_CFW=newArray();	
inc=0;
for (img = 0; img < list_Imgs.length; img++) {				
	if (endsWith(list_Imgs[img], "_CFW.tif")) {
		list_CFW[inc] = list_Imgs[img];
		inc++;				
	}							
}
//Array.show(list_CFW);

for (img = 0; img < list_CFW.length; img++) {	
	
	open(rootDir + list_CFW[img]);	
	rename("MAX_Original");
	run("Select None");
	
	open(rootDir_seg + list_CFW[img]);	
	rename("Segmentation");
	run("Select None");

	selectImage("MAX_Original");
	run("Duplicate...", "title=Mask");
	setAutoThreshold("Default dark");
	run("Convert to Mask");
	run("Fill Holes");

	// Noise reduction in final segmentation
	// Remove possible detected segments around the wellplate
	run("Morphological Filters", "operation=Erosion element=Disk radius=5");
	imageCalculator("Multiply", "Segmentation","Mask-Erosion");
	
	// label
	selectImage("Segmentation");
	run("Connected Components Labeling", "connectivity=8 type=[16 bits]");

	// Remove line artifacts!
	selectImage("Segmentation-lbl");
	run("Analyze Regions", "ellipse_elong. max._inscribed_disc");
	Table.rename("Segmentation-lbl-Morphometry", "Results");

	selectImage("Segmentation-lbl");
	for (i = 0; i < nResults(); i++) {
	    Elng = getResult("Ellipse.Elong", i);  
	    MFD = getResult("MaxFeretDiam", i); 
	    IDR = getResult("InscrDisc.Radius", i);
	    if ( (Elng>20) && (IDR<10) ) {
			label_obj=i+1;
			run("Replace/Remove Label(s)", "label(s)="+label_obj+" final=0");
		}   
	}	

	// Relabel
	selectImage("Segmentation-lbl");
	setThreshold(1.0, 1.0E+30);
	run("Convert to Mask");
	
	// Save Segmentation & Close
	saveAs("Tiff", outputDir + list_CFW[img]);	
	close("*");
	close("Results");
}