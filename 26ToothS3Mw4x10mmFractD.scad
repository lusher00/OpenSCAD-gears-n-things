use <sXm-pulley.scad>

teeth = 26;
belt_width = 4;

// Bore
bore = 10.0;
flat_depth = 1.50;       // 0 = round bore, 1.5 = D-shaft flat
round_slip_h = 2.0;      // round section before D-flat starts
bore_r = bore / 2;
eps = 0.05;

// Bearing offset base / spacer
base_d = 12;
base_h = 0.0;

// Flanges
bottom_flange_h = 1.20;
top_flange_h = 1.20;
flange_chamfer = 0.750;
flange_extra = 1.0;

// Edge chamfer
edge_chamfer = 0.75;

// Lightening holes
lighten_holes = 9;
lighten_d = 3.25;
lighten_r = 8.2;
hole_chamfer = 0.75;

tooth_r = s3m_pulley_base_outer_r(teeth);
flange_r = tooth_r + flange_extra;

z_min = -bottom_flange_h;
z_max = belt_width + top_flange_h;
pulley_h = belt_width + bottom_flange_h + top_flange_h;

bottom_lip_h = bottom_flange_h - flange_chamfer;
top_lip_h = top_flange_h - flange_chamfer;

module d_bore_cut(h) {
    intersection() {
        cylinder(d=bore, h=h, $fn=100);

        translate([-bore_r, -bore_r, 0])
            cube([bore, bore - flat_depth, h]);
    }
}

module bore_cut(h) {
    if (flat_depth <= 0) {
        cylinder(d=bore, h=h, $fn=100);
    } else {
        union() {
            // round entry
            cylinder(d=bore, h=round_slip_h + eps, $fn=100);

            // D-bore overlaps round section slightly so no membrane remains
            translate([0,0,round_slip_h - eps])
                d_bore_cut(h - round_slip_h + 2*eps);
        }
    }
}

difference() {
    union() {
        // bearing offset base / spacer
        translate([0,0,z_min - base_h])
            cylinder(d=base_d, h=base_h, $fn=100);

        // S3M toothed section
        s3m_pulley_base(teeth, belt_width);

        // bottom flat lip
        translate([0,0,z_min])
            cylinder(r=flange_r, h=bottom_lip_h, $fn=120);

        // bottom chamfer
        translate([0,0,z_min + bottom_lip_h])
            cylinder(
                r1 = flange_r,
                r2 = tooth_r,
                h = flange_chamfer,
                $fn = 120
            );

        // top chamfer
        translate([0,0,belt_width])
            cylinder(
                r1 = tooth_r,
                r2 = flange_r,
                h = flange_chamfer,
                $fn = 120
            );

        // top flat lip
        translate([0,0,belt_width + flange_chamfer])
            cylinder(r=flange_r, h=top_lip_h, $fn=120);
    }

    // main bore through pulley and spacer
    translate([0,0,z_min - base_h - eps])
        bore_cut(pulley_h + base_h + 2*eps);

    // lightening holes
    for (i = [0 : lighten_holes - 1]) {
        rotate([0,0,i * 360 / lighten_holes])
            translate([lighten_r,0,z_min - 1])
                cylinder(d=lighten_d, h=pulley_h + 2, $fn=50);
    }

    // bottom chamfer around lightening holes
    for (i = [0 : lighten_holes - 1]) {
        rotate([0,0,i * 360 / lighten_holes])
            translate([lighten_r,0,z_min - 0.01])
                cylinder(
                    d1 = lighten_d + 2*hole_chamfer,
                    d2 = lighten_d,
                    h = hole_chamfer,
                    $fn = 50
                );
    }

    // top chamfer around lightening holes
    for (i = [0 : lighten_holes - 1]) {
        rotate([0,0,i * 360 / lighten_holes])
            translate([lighten_r,0,z_max - hole_chamfer + 0.01])
                cylinder(
                    d1 = lighten_d,
                    d2 = lighten_d + 2*hole_chamfer,
                    h = hole_chamfer,
                    $fn = 50
                );
    }
}