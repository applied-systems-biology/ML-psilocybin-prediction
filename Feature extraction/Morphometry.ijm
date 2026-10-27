// ============================================================
// CFW MORPHOMETRY QUANTIFICATION
// ============================================================

setBatchMode("true");
setBatchMode("hide");
setOption("ExpandableArrays", true);


// ============================================================
// USER SETTINGS
// ============================================================

rootDir   = ".../Segmentation watershed/"; // Define the root directory
outputDir = ".../Image-derived features/"; // Define the output directory
outputName = "Morphometry.csv"; // Define the file name

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

// Morphometry
values_Area = newArray();
values_Perimeter = newArray();
values_Circularity = newArray();
values_EulerNumber = newArray();

values_EllipseRadius1 = newArray();
values_EllipseRadius2 = newArray();
values_EllipseOrientation = newArray();
values_EllipseElong = newArray();

values_MaxFeretDiam = newArray();
values_MaxFeretDiamAngle = newArray();

values_OBoxLength = newArray();
values_OBoxWidth = newArray();
values_OBoxOrientation = newArray();

values_GeodesicDiameter = newArray();
values_Tortuosity = newArray();
values_InscrDiscRadius = newArray();
values_GeodesicElongation = newArray();


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
    rename("CFW");


    // --------------------------------------------------------
    // LABEL + MORPHOMETRY
    // --------------------------------------------------------

    run(
        "Connected Components Labeling",
        "connectivity=8 type=[16 bits]"
    );

    run(
        "Analyze Regions",
        "area perimeter circularity euler_number bounding_box centroid equivalent_ellipse ellipse_elong. max._feret_diameter oriented_box oriented_box_elong. geodesic_diameter tortuosity max._inscribed_disc geodesic_elong."
    );

    Table.rename(
        "CFW-lbl-Morphometry",
        "Results"
    );


    // --------------------------------------------------------
    // GET MORPHOMETRY
    // IMPORTANT:
    // Keep Table.getColumn and Array.concat separate
    // --------------------------------------------------------

    Area = Table.getColumn("Area");
    values_Area = Array.concat(values_Area, Area);

    Perimeter = Table.getColumn("Perimeter");
    values_Perimeter = Array.concat(values_Perimeter, Perimeter);

    Circularity = Table.getColumn("Circularity");
    values_Circularity = Array.concat(values_Circularity, Circularity);

    EulerNumber = Table.getColumn("EulerNumber");
    values_EulerNumber = Array.concat(values_EulerNumber, EulerNumber);


    EllipseRadius1 = Table.getColumn("Ellipse.Radius1");
    values_EllipseRadius1 = Array.concat(
        values_EllipseRadius1,
        EllipseRadius1
    );

    EllipseRadius2 = Table.getColumn("Ellipse.Radius2");
    values_EllipseRadius2 = Array.concat(
        values_EllipseRadius2,
        EllipseRadius2
    );

    EllipseOrientation = Table.getColumn("Ellipse.Orientation");
    values_EllipseOrientation = Array.concat(
        values_EllipseOrientation,
        EllipseOrientation
    );

    EllipseElong = Table.getColumn("Ellipse.Elong");
    values_EllipseElong = Array.concat(
        values_EllipseElong,
        EllipseElong
    );


    MaxFeretDiam = Table.getColumn("MaxFeretDiam");
    values_MaxFeretDiam = Array.concat(
        values_MaxFeretDiam,
        MaxFeretDiam
    );

    MaxFeretDiamAngle = Table.getColumn("MaxFeretDiamAngle");
    values_MaxFeretDiamAngle = Array.concat(
        values_MaxFeretDiamAngle,
        MaxFeretDiamAngle
    );


    OBoxLength = Table.getColumn("OBox.Length");
    values_OBoxLength = Array.concat(
        values_OBoxLength,
        OBoxLength
    );

    OBoxWidth = Table.getColumn("OBox.Width");
    values_OBoxWidth = Array.concat(
        values_OBoxWidth,
        OBoxWidth
    );

    OBoxOrientation = Table.getColumn("OBox.Orientation");
    values_OBoxOrientation = Array.concat(
        values_OBoxOrientation,
        OBoxOrientation
    );


    GeodesicDiameter = Table.getColumn("GeodesicDiameter");
    values_GeodesicDiameter = Array.concat(
        values_GeodesicDiameter,
        GeodesicDiameter
    );

    Tortuosity = Table.getColumn("Tortuosity");
    values_Tortuosity = Array.concat(
        values_Tortuosity,
        Tortuosity
    );

    InscrDiscRadius = Table.getColumn("InscrDisc.Radius");
    values_InscrDiscRadius = Array.concat(
        values_InscrDiscRadius,
        InscrDiscRadius
    );

    GeodesicElongation = Table.getColumn("GeodesicElongation");
    values_GeodesicElongation = Array.concat(
        values_GeodesicElongation,
        GeodesicElongation
    );


    // --------------------------------------------------------
    // CONDITIONS FROM FILE NAME
    // SAME LOGIC AS YOUR ORIGINAL CODE
    // --------------------------------------------------------

    string_spl = split(list_seg[img], "_");

    values_experiment_current = newArray(nResults);
    values_bioreactor_current = newArray(nResults);
    values_time_current = newArray(nResults);
    values_wellplates_current = newArray(nResults);


    for (i = 0; i < nResults(); i++) {

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

Table.create("Table_Morphometry");


// Conditions
Table.setColumn("Experiment", values_experiment);
Table.setColumn("Bioreactor", values_bioreactor);
Table.setColumn("Time point (h)", values_time);
Table.setColumn("Wellplate", values_wellplates);


// Morphometry
Table.setColumn("Area", values_Area);
Table.setColumn("Perimeter", values_Perimeter);
Table.setColumn("Circularity", values_Circularity);
Table.setColumn("EulerNumber", values_EulerNumber);

Table.setColumn("Ellipse.Radius1", values_EllipseRadius1);
Table.setColumn("Ellipse.Radius2", values_EllipseRadius2);
Table.setColumn("Ellipse.Orientation", values_EllipseOrientation);
Table.setColumn("Ellipse.Elong", values_EllipseElong);

Table.setColumn("MaxFeretDiam", values_MaxFeretDiam);
Table.setColumn("MaxFeretDiamAngle", values_MaxFeretDiamAngle);

Table.setColumn("OBox.Length", values_OBoxLength);
Table.setColumn("OBox.Width", values_OBoxWidth);
Table.setColumn("OBox.Orientation", values_OBoxOrientation);

Table.setColumn("GeodesicDiameter", values_GeodesicDiameter);
Table.setColumn("Tortuosity", values_Tortuosity);
Table.setColumn("InscrDisc.Radius", values_InscrDiscRadius);
Table.setColumn("GeodesicElongation", values_GeodesicElongation);


// ============================================================
// SAVE
// ============================================================

Table.rename(
    "Table_Morphometry",
    "Results"
);

saveAs(
    "Results",
    outputDir + outputName
);

setBatchMode(false);

print("");
print("================================================");
print("QUANTIFICATION FINISHED");
print("Saved to:");
print(outputDir + outputName);
print("================================================");