// ============================================================
// COMPLETE CFW SEGMENTATION PIPELINE
// Stage 1: Combined segmentation
// Stage 2: Artifact removal + area filter
// Stage 3: Watershed separation
// ============================================================

setBatchMode("true");
setBatchMode("hide");
setOption("BlackBackground", true);
setOption("ExpandableArrays", true);


// ============================================================
// USER SETTINGS
// ============================================================

// Paths
rootDir   = "H:/Dataset/";
outputDir = "D:/Analysis/";

// Stage 1 - Combined segmentation
S1_thresholdMethod1 = "Default";
S1_thresholdMethod2 = "Percentile";
S1_thresholdMultiplier = 1.5;
S1_wait = 200;
S1_subdivision = 2;
S1_pixelWidth = 3.77442;
S1_pixelHeight = 3.77442;
S1_voxelDepth = 1;
S1_tubenessSigma = 5;
S1_NLM_sigma = 5;
S1_NLM_smoothing = 1;
S1_convolutionKernel = "[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n]";
S1_ridge_lineWidth = 5;
S1_ridge_highContrast = 230;
S1_ridge_lowContrast = 87;
S1_ridge_sigma = 1.94;
S1_ridge_lowerThreshold = 1.70;
S1_ridge_upperThreshold = 4.59;
S1_ridge_minLineLength = 3;
S1_ridge_maximum = 0;

// Stage 2 - Artifact removal + area filter
S2_maskThresholdMethod = "Default";
S2_erosionRadius = 5;
S2_maxElongation = 20;
S2_minInscribedRadius = 10;
S2_areaMin = 500;
S2_pixelWidth = 3.77442;
S2_pixelHeight = 3.77442;
S2_voxelDepth = 1;
S2_surfaceResampling = 2;
S2_split = 0.000;
S2_volumeResampling = 2;

// Stage 3 - Watershed
S3_areaMin = 500;
S3_feretMin = 500;
S3_ResXY = 3.7744;
S3_openingRadius = 2;
S3_closingRadius = 2;
S3_seedAreaMin = 1000;
S3_watershedRadius = 2;


// ============================================================
// OUTPUT FOLDERS
// ============================================================

segmentationDir = outputDir + "01_Combined_Segmentation/";
artifactDir     = outputDir + "02_Artifact_Removed/";
watershedDir    = outputDir + "03_Watershed/";

File.makeDirectory(outputDir);
File.makeDirectory(segmentationDir);
File.makeDirectory(artifactDir);
File.makeDirectory(watershedDir);


// ============================================================
// FIND CFW IMAGES
// ============================================================

list_Imgs = getFileList(rootDir);
list_CFW = newArray();
inc = 0;

for (img = 0; img < list_Imgs.length; img++) {
    if (endsWith(list_Imgs[img], "_CFW.tif")) {
        list_CFW[inc] = list_Imgs[img];
        inc++;
    }
}


// ============================================================
// PROCESS IMAGES
// ============================================================

for (img = 0; img < list_CFW.length; img++) {

    print("");
    print("================================================");
    print("Processing " + (img+1) + " / " + list_CFW.length);
    print(list_CFW[img]);
    print("================================================");


    // ========================================================
    // STAGE 1 - COMBINED SEGMENTATION
    // ========================================================

    print("1/3 - Combined segmentation");

    open(rootDir + list_CFW[img]);
    rename("MAX_Original");

    // Global threshold segmentation
    run("Duplicate...", "title=Combined_Segmentation");
    run("32-bit");
    setAutoThreshold(S1_thresholdMethod1 + " dark");
    run("NaN Background");
    wait(S1_wait);
    setAutoThreshold(S1_thresholdMethod2 + " dark");
    getThreshold(lower, upper);
    setThreshold(S1_thresholdMultiplier * lower, upper);
    run("Convert to Mask");

    // Image subdivision
    selectImage("MAX_Original");
    w = getWidth();
    h = getHeight();
    stepSizeW = w / S1_subdivision;
    stepSizeH = h / S1_subdivision;

    // Ridge detection output image
    newImage("Ridge_Detection", "8-bit black", w, h, 1);
    Stack.setXUnit("micron");
    run("Properties...",
        "pixel_width="+S1_pixelWidth+
        " pixel_height="+S1_pixelHeight+
        " voxel_depth="+S1_voxelDepth);

    // Process sub-regions
    for (i = 0; i < round(h/stepSizeH); i++) {
        for (j = 0; j < round(w/stepSizeW); j++) {

            x = j * stepSizeW;
            y = i * stepSizeH;

            selectImage("MAX_Original");
            makeRectangle(x, y, stepSizeW, stepSizeH);
            run("Duplicate...", "title=MAX_Original_SubR");

            // Signal enhancement
            run("Tubeness", "sigma="+S1_tubenessSigma+" use");
            run("8-bit");
            run("Non-local Means Denoising",
                "sigma="+S1_NLM_sigma+
                " smoothing_factor="+S1_NLM_smoothing);
            run("Convolve...",
                "text1="+S1_convolutionKernel+" normalize");
            run("Smooth");

            // Ridge detection
            run("Ridge Detection",
                "line_width="+S1_ridge_lineWidth+
                " high_contrast="+S1_ridge_highContrast+
                " low_contrast="+S1_ridge_lowContrast+
                " extend_line make_binary"+
                " method_for_overlap_resolution=NONE"+
                " sigma="+S1_ridge_sigma+
                " lower_threshold="+S1_ridge_lowerThreshold+
                " upper_threshold="+S1_ridge_upperThreshold+
                " minimum_line_length="+S1_ridge_minLineLength+
                " maximum="+S1_ridge_maximum);

            run("Invert LUT");
            rename("MAX_Original_SubR_Detected_segments");

            // Insert sub-region into full ridge image
            run("Insert...",
                "source=MAX_Original_SubR_Detected_segments"+
                " destination=Ridge_Detection"+
                " x="+x+" y="+y);

            // Close temporary images
            list = getList("image.titles");
            for (id = 0; id < list.length; id++) {
                title = list[id];
                if (!(title == "MAX_Original" ||
                      title == "Ridge_Detection" ||
                      title == "Combined_Segmentation")) {
                    close(list[id]);
                }
            }
        }
    }

    // Combine threshold + ridge segmentation
    imageCalculator("Add", "Combined_Segmentation", "Ridge_Detection");

    // Save Stage 1
    selectImage("Combined_Segmentation");
    saveAs("Tiff", segmentationDir + list_CFW[img]);
    rename("Segmentation");


    // ========================================================
    // STAGE 2 - ARTIFACT REMOVAL + AREA FILTER
    // ========================================================

    print("2/3 - Artifact removal");

    // Mask from original image
    selectImage("MAX_Original");
    run("Select None");
    run("Duplicate...", "title=Mask");
    setAutoThreshold(S2_maskThresholdMethod + " dark");
    run("Convert to Mask");
    run("Fill Holes");

    // Remove wellplate-edge artifacts
    run("Morphological Filters",
        "operation=Erosion element=Disk radius="+S2_erosionRadius);

    imageCalculator("Multiply", "Segmentation", "Mask-Erosion");

    // Connected components
    selectImage("Segmentation");
    run("Connected Components Labeling",
        "connectivity=8 type=[16 bits]");

    // Remove line artifacts
    selectImage("Segmentation-lbl");
    run("Analyze Regions",
        "ellipse_elong. max._inscribed_disc");

    Table.rename("Segmentation-lbl-Morphometry", "Results");

    selectImage("Segmentation-lbl");

    for (i = 0; i < nResults(); i++) {

        Elng = getResult("Ellipse.Elong", i);
        MFD  = getResult("MaxFeretDiam", i);
        IDR  = getResult("InscrDisc.Radius", i);

        if ((Elng > S2_maxElongation) &&
            (IDR < S2_minInscribedRadius)) {

            label_obj = i + 1;

            run("Replace/Remove Label(s)",
                "label(s)="+label_obj+" final=0");
        }
    }

    // Convert to binary mask
    selectImage("Segmentation-lbl");
    setThreshold(1.0, 1.0E+30);
    run("Convert to Mask");
    rename("Artifact_Removed");

    close("Results");

    // Area filter
    selectImage("Artifact_Removed");
    Stack.setXUnit("micron");

    run("Properties...",
        "pixel_width="+S2_pixelWidth+
        " pixel_height="+S2_pixelHeight+
        " voxel_depth="+S2_voxelDepth);

    run("Particle Analyser",
        "  min="+S2_areaMin+
        " max=Infinity"+
        " surface_resampling="+S2_surfaceResampling+
        " show_particle surface=Gradient"+
        " split="+S2_split+
        " volume_resampling="+S2_volumeResampling);

    setOption("BlackBackground", true);
    setThreshold(1.0000, 1.0000E+32);
    run("Convert to Mask");

    rename("Artifact_Removed_Final");

    // Save Stage 2
    saveAs("Tiff", artifactDir + list_CFW[img]);
    rename("Artifact_Removed_Final");

    // Keep only cleaned segmentation
    list = getList("image.titles");
    for (id = 0; id < list.length; id++) {
        title = list[id];

        if (title != "Artifact_Removed_Final") {
            close(list[id]);
        }
    }


    // ========================================================
    // STAGE 3 - WATERSHED SEPARATION
    // ========================================================

    print("3/3 - Watershed separation");

    selectImage("Artifact_Removed_Final");
    rename("Original");

    // Identify large microcolonies
    run("Duplicate...", "title=Microcolony");

    run("Shape Filter",
        "feret_diameter="+S3_feretMin+
        "-Infinity draw_holes black_background");

    getStatistics(area, mean, min, max, std, histogram);


    // --------------------------------------------------------
    // LARGE OBJECTS PRESENT -> WATERSHED
    // --------------------------------------------------------

    if (max == 255) {

        // Separate individual objects from large microcolonies
        imageCalculator("Subtract create", "Original", "Microcolony");
        rename("Microcolony-Individual");

        // Seed estimation
        selectImage("Microcolony");

        run("Morphological Filters",
            "operation=Opening element=Disk radius="+S3_openingRadius);

        run("Morphological Filters",
            "operation=Closing element=Disk radius="+S3_closingRadius);

        run("Shape Filter",
            "area="+S3_seedAreaMin+
            "-Infinity draw_holes black_background");

        rename("seeds2D");


        // Detect objects lost during opening
        selectImage("Microcolony");

        run("Connected Components Labeling",
            "connectivity=8 type=[16 bits]");

        selectImage("seeds2D");

        run("Duplicate...",
            "title=seeds2D-thresholded");

        setThreshold(1.0000, 1.0000E+30);
        run("Convert to Mask");

        run("Intensity Measurements 2D/3D",
            "input=seeds2D-thresholded"+
            " labels=Microcolony-lbl"+
            " mean max min");

        Table.rename(
            "seeds2D-thresholded-intensity-measurements",
            "Results"
        );

        selectImage("Microcolony-lbl");

        for (i = 0; i < nResults; i++) {

            max = getResult("Max", i);

            if (max == 255) {

                lbl = i + 1;

                run("Replace/Remove Label(s)",
                    "label(s)="+lbl+" final=0");
            }
        }

        rename("Lost_objects");

        setThreshold(1.0000, 1.0000E+30);
        run("Convert to Mask");

        close("Results");
        close("seeds2D-thresholded");


        // Watershed split
        run("3D Watershed Split",
            "binary=Microcolony"+
            " seeds=seeds2D"+
            " radius="+S3_watershedRadius);

        Stack.setXUnit("micron");

        run("Properties...",
            "pixel_width="+S3_ResXY+
            " pixel_height="+S3_ResXY+
            " voxel_depth=1");

        setThreshold(1.0000, 1.000E+30);
        run("Convert to Mask", "background=Dark black");


        // Add individual and lost objects back
        imageCalculator("Add", "Split", "Microcolony-Individual");
        imageCalculator("Add", "Split", "Lost_objects");


        // Final area filter
        selectImage("Split");

        run("Shape Filter",
            "area="+S3_areaMin+
            "-Infinity draw_holes black_background");


        // Save final watershed result
        baseName = substring(
            list_CFW[img],
            0,
            lastIndexOf(list_CFW[img], ".tif")
        );

        saveAs(
            "Tiff",
            watershedDir + baseName + "_Splitted"
        );

        close("Results");
        close("*");
    }


    // --------------------------------------------------------
    // NO LARGE OBJECTS -> SAVE ORIGINAL CLEAN SEGMENTATION
    // --------------------------------------------------------

    else {

        selectImage("Original");

        baseName = substring(
            list_CFW[img],
            0,
            lastIndexOf(list_CFW[img], ".tif")
        );

        saveAs(
            "Tiff",
            watershedDir + baseName + "_Original"
        );

        close("Results");
        close("*");
    }


    print("Finished: " + list_CFW[img]);
}


// ============================================================
// FINISHED
// ============================================================

setBatchMode(false);

print("");
print("================================================");
print("ALL IMAGES FINISHED");
print("Results saved in:");
print(outputDir);
print("================================================");