// ============================================================
// CFW EROSION SURVIVAL ANALYSIS
// ============================================================

setBatchMode("true");
setBatchMode("hide");


// ============================================================
// USER SETTINGS
// ============================================================

rootDir   = ".../Segmentation watershed/"; // Define the root directory
outputDir = "../Image-derived features/"; // Define the output directory
outputName = "Erosion survival fraction.csv"; // Define the file name

Max_Erosion = 200;

File.makeDirectory(outputDir);


// ============================================================
// INPUT FILES
// ============================================================

list_seg = getFileList(rootDir);


// ============================================================
// ARRAYS FOR FINAL RESULTS
// ============================================================

// Experimental conditions
values_experiment = newArray();
values_bioreactor = newArray();
values_time = newArray();
values_wellplates = newArray();

// Survival analysis
values_Disk = newArray();
values_Area = newArray();

N = Max_Erosion + 1;


// ============================================================
// PROCESS SEGMENTATIONS
// ============================================================

for (img = 0; img < list_seg.length; img++) {

    // Only process TIFF files
    if (!endsWith(list_seg[img], ".tif"))
        continue;

    print("Processing " + (img+1) + " / " + list_seg.length);
    print(list_seg[img]);

    open(rootDir + list_seg[img]);
    rename("Segmentation");


    // --------------------------------------------------------
    // STARTING AREA
    // --------------------------------------------------------

    selectImage("Segmentation");

    run(
        "Analyze Particles...",
        "summarize"
    );

    area_all = Table.get("Total Area", 0);

    values_Area = Array.concat(values_Area, 1);
    values_Disk = Array.concat(values_Disk, 0);

    close("Summary");


    // --------------------------------------------------------
    // EROSION SURVIVAL
    // --------------------------------------------------------

    for (i = 1; i < N; i++) {

        selectImage("Segmentation");

        run(
            "Morphological Filters",
            "operation=Erosion element=Disk radius="+i
        );

        run(
            "Analyze Particles...",
            "summarize"
        );

        area_left = Table.get("Total Area", 0) / area_all;

        close("Segmentation-Erosion");
        close("Summary");


        if (area_left != 0) {

            values_Area = Array.concat(
                values_Area,
                area_left
            );

            values_Disk = Array.concat(
                values_Disk,
                i
            );

        } else {

            remaining = N - i;

            area_left_remaining = newArray(remaining);
            disk_size_remaining = newArray(remaining);

            for (index = 0; index < remaining; index++) {
                disk_size_remaining[index] = i + index;
            }

            values_Area = Array.concat(
                values_Area,
                area_left_remaining
            );

            values_Disk = Array.concat(
                values_Disk,
                disk_size_remaining
            );

            break;
        }
    }


    // --------------------------------------------------------
    // CONDITIONS FROM FILE NAME
    // SAME LOGIC AS YOUR ORIGINAL CODE
    // --------------------------------------------------------

    string_spl = split(list_seg[img], "_");

    values_experiment_current = newArray(N);
    values_bioreactor_current = newArray(N);
    values_time_current = newArray(N);
    values_wellplates_current = newArray(N);


    for (i = 0; i < N; i++) {

        values_experiment_current[i] =
            string_spl[0];

        values_bioreactor_current[i] =
            string_spl[2];

        values_time_current[i] =
            substring(
                string_spl[string_spl.length-7],
                0,
                lastIndexOf(
                    string_spl[string_spl.length-7],
                    "h"
                )
            );

        values_wellplates_current[i] =
            string_spl[string_spl.length-3];
    }


    values_experiment = Array.concat(
        values_experiment,
        values_experiment_current
    );

    values_bioreactor = Array.concat(
        values_bioreactor,
        values_bioreactor_current
    );

    values_time = Array.concat(
        values_time,
        values_time_current
    );

    values_wellplates = Array.concat(
        values_wellplates,
        values_wellplates_current
    );


    // --------------------------------------------------------
    // CLEAN UP
    // --------------------------------------------------------

    close("*");
    close("Results");
}


// ============================================================
// CREATE FINAL TABLE
// ============================================================

Table.create("Table_Survival");


// Conditions
Table.setColumn("Experiment", values_experiment);
Table.setColumn("Bioreactor", values_bioreactor);
Table.setColumn("Time point (h)", values_time);
Table.setColumn("Wellplate", values_wellplates);


// Survival analysis
Table.setColumn("Disk size", values_Disk);
Table.setColumn("Erosion Survival Fraction", values_Area);


// ============================================================
// SAVE
// ============================================================

Table.rename(
    "Table_Survival",
    "Results"
);

saveAs(
    "Results",
    outputDir + outputName
);

setBatchMode(false);

print("");
print("================================================");
print("EROSION SURVIVAL ANALYSIS FINISHED");
print("Saved to:");
print(outputDir + outputName);
print("================================================");