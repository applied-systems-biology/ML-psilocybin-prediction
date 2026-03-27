setBatchMode("true");
setBatchMode("hide");

// Define the root directory
rootDir = ".../Segmentation watershed/";
outputDir = ".../Image-derived features/";
//File.makeDirectory(outputDir);

// Get the list of the CFW images
list_CFW = getFileList(rootDir);
Array.show(list_CFW);

// To save results
values_experiment = newArray();
values_bioreactor = newArray();
values_time = newArray();
values_wellplates = newArray();
values_Disk = newArray();
values_Area = newArray();

Max_Erosion=200;
N = Max_Erosion+1;
for (img = list_CFW.length-2; img < list_CFW.length-1; img++) {	
	
	open(rootDir + list_CFW[img]);
	rename("Segmentation");
	
	selectImage("Segmentation");
	run("Analyze Particles...", "summarize");
	area_all = Table.get("Total Area", 0);
	values_Area=Array.concat(values_Area,1);
	values_Disk=Array.concat(values_Disk,0);
	close("Summary");
		
	for (i = 1; i < N; i++) {
		
		selectImage("Segmentation");
		run("Morphological Filters", "operation=Erosion element=Disk radius=i");
		run("Analyze Particles...", "summarize");
		area_left = Table.get("Total Area", 0)/area_all;
		close("Segmentation-Erosion");
		close("Summary");
		
		if (area_left!=0) {
			values_Area=Array.concat(values_Area,area_left);
			values_Disk=Array.concat(values_Disk,i);		
		}else {
			remaining = N-i;
			area_left_remaining = newArray(remaining);
			disk_size_remaining = newArray(remaining);
			
			// Fill the array with values from i to n
			for (index = 0; index < disk_size_remaining.length; index++) {
			    disk_size_remaining[index] = i + index;
			}

			values_Area=Array.concat(values_Area,area_left_remaining);
			values_Disk=Array.concat(values_Disk,disk_size_remaining);
			break;
		}
		
	}

	// Conditions
	string_spl=split(list_CFW[img], "_");
	
	values_experiment_current = newArray(N);
	values_bioreactor_current = newArray(N);
	values_time_current = newArray(N);
	values_wellplates_current = newArray(N);
	
	for (i = 0; i < N; i++) {
	    values_experiment_current[i] = string_spl[0];	    
	    /*
	    if (string_spl[0]=="AP00824") {
	    	values_bioreactor_current[i] = string_spl[2] + " " + string_spl[3];
	    }else {
	    	values_bioreactor_current[i] = string_spl[2];
	    }	 
	    */
	    values_bioreactor_current[i] = string_spl[2];
	    values_time_current[i] = substring(string_spl[string_spl.length-7], 0,lastIndexOf(string_spl[string_spl.length-7], "h"));
	    values_wellplates_current[i] = string_spl[string_spl.length-3];
	}
	
	values_experiment=Array.concat(values_experiment,values_experiment_current);
	values_bioreactor=Array.concat(values_bioreactor,values_bioreactor_current);
	values_time=Array.concat(values_time,values_time_current);
	values_wellplates=Array.concat(values_wellplates,values_wellplates_current);

	close("*");
	close("Results");
}


// Create table to save results
Table.create("Table_Survival");
// set a whole column
Table.setColumn("Experiment", values_experiment);
Table.setColumn("Bioreactor", values_bioreactor);
Table.setColumn("Time point (h)", values_time);
Table.setColumn("Wellplate", values_wellplates);
Table.setColumn("Disk size", values_Disk);
Table.setColumn("Erosion Survival Fraction", values_Area);

Table.rename("Table_Survival", "Results");
saveAs("Results", outputDir + "Survival_Analysis_F3F8_F896hXY20.csv");
