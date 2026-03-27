setBatchMode("true");
setBatchMode("hide");
setOption("BlackBackground", true);
setOption("ExpandableArrays", true);

// Define the root and output directory
rootDir = ".../Imaging data/";
outputDir = ".../Segmentation/";
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

	// Colonies detection by global thresholding
	run("Duplicate...", "title=Final_Segmentation");
	//run("Subtract Background...", "rolling=200");
	//setAutoThreshold("Otsu dark");
	//run("Convert to Mask");
	run("32-bit");
	setAutoThreshold("Default dark");
	run("NaN Background");
	wait(200);
	setAutoThreshold("Percentile dark");
	getThreshold(lower, upper);
	setThreshold(1.5*lower, upper); //1.5
	run("Convert to Mask");

	// Go through sub-regions
	selectImage("MAX_Original");
	w=getWidth();
	h=getHeight();
	stepSizeW=w/2;
	stepSizeH=h/2;

	// To save results
	newImage("Ridge_Detection", "8-bit black", w, h, 1);
	Stack.setXUnit("micron");
	run("Properties...", "pixel_width=3.77442 pixel_height=3.77442 voxel_depth=1");

	for (i=0;i<round(h/stepSizeH);i++){
		for (j=0;j<round(w/stepSizeW);j++){		
			x=j*stepSizeW;
	        y=i*stepSizeH;
			
			selectImage("MAX_Original");
			makeRectangle(x, y, stepSizeW, stepSizeH);
			run("Duplicate...", "title=MAX_Original_SubR");
			
			// Signal enhancement for ridge detection
			run("Tubeness", "sigma=5 use");
			run("8-bit");
			run("Non-local Means Denoising", "sigma=5 smoothing_factor=1");
			run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n] normalize");
			run("Smooth");		
	
			// Ridge Detection
			run("Ridge Detection", "line_width=5 high_contrast=230 low_contrast=87 extend_line make_binary method_for_overlap_resolution=NONE sigma=1.94 lower_threshold=1.70 upper_threshold=4.59 minimum_line_length=3 maximum=0");
			//run("Ridge Detection", "line_width=5 high_contrast=500 low_contrast=400 extend_line make_binary method_for_overlap_resolution=NONE sigma=1.94 lower_threshold=7.99 upper_threshold=10.03 minimum_line_length=3 maximum=0"); //Exception
			run("Invert LUT");
			rename("MAX_Original_SubR_Detected_segments");
				
			run("Insert...", "source=MAX_Original_SubR_Detected_segments destination=Ridge_Detection x=x y=y");

			// Close all except 2 output images
			list = getList("image.titles");
			// Loop through each open image and close it if the title is not one in list
			for (id = 0; id < list.length; id++) {
			    title = list[id];
			    if (!(title== "MAX_Original" || title == "Ridge_Detection" || title == "Final_Segmentation")) {
			        close(list[id]);
			    }
			}
			
		}	
	}
	
	// Add
	imageCalculator("Add", "Final_Segmentation","Ridge_Detection");

	/* This fails at intensity based artifacts removing!!!
	// Noise reduction in final segmentation
	// Remove possible detected segments around the wellplate
	selectImage("MAX_Original");
	run("Select None");
	run("Duplicate...", "title=Ring");
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
	run("Morphological Filters", "operation=Erosion element=Disk radius=30");
	imageCalculator("Subtract", "Ring","Ring-Erosion");
	close("Ring-Erosion");
	run("Intensity Measurements 2D/3D", "input=MAX_Original labels=Ring mean stddev max min");
	Ring_mean = getResult("Mean", 0);
	close("Ring");
	close("Results");
	
	selectImage("Final_Segmentation");
	run("Connected Components Labeling", "connectivity=8 type=[16 bits]");
	run("Intensity Measurements 2D/3D", "input=MAX_Original labels=Final_Segmentation-lbl mean stddev max min");
	Table.rename("MAX_Original-intensity-measurements", "Results");
	
	for (i = 0; i < nResults(); i++) {
		mean = getResult("Mean", i);
		if (mean<Ring_mean) {
			label_obj=i+1;
			run("Replace/Remove Label(s)", "label(s)="+label_obj+" final=0");
		}   
	}	
	close("Results");
	
	// Relabel
	selectImage("Final_Segmentation-lbl");
	run("Connected Components Labeling", "connectivity=8 type=[16 bits]");

	// Remove line artifacts!
	selectImage("Final_Segmentation-lbl-lbl");
	run("Analyze Regions", "area ellipse_elong. max._feret max._inscribed_disc");
	Table.rename("Final_Segmentation-lbl-lbl-Morphometry", "Results");

	selectImage("Final_Segmentation-lbl-lbl");
	for (i = 0; i < nResults(); i++) {
	    Area = getResult("Area", i);
	    Elng = getResult("Ellipse.Elong", i);  
	    MFD = getResult("MaxFeretDiam", i); 
	    IDR = getResult("InscrDisc.Radius", i);
	    if ( (Area<200) | ((Elng>30) && (IDR<10)) ) {
			label_obj=i+1;
			run("Replace/Remove Label(s)", "label(s)="+label_obj+" final=0");
		}   
	}	

	// Relabel
	selectImage("Final_Segmentation-lbl-lbl");
	setThreshold(1.0, 1.0E+30);
	run("Convert to Mask");
	*/

	// Save Segmentation & Close
	selectImage("Final_Segmentation");
	saveAs("Tiff", outputDir + list_CFW[img]);	
	close("*");
	close("Results");
}

