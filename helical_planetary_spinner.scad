/* ============================================================
   CROSSED-HELICAL PLANETARY FIDGET SPINNER
   ------------------------------------------------------------
   A sun gear on the vertical axis meshing with 3 "transverse"
   planet gears whose axes are at 90 deg to the sun axis.
   Both gears are helical with a 45 deg helix and the SAME hand:
   a 45/45 crossed-helical pair meshes at exactly 90 deg.

   Fully parametric: module, tooth counts, helix, spokes,
   chamfers, bearing seats (races), carrier and caps.

   PARTS TO PRINT (set `part`):
     sun        x1   (prints flat, no supports)
     planet     x3   (prints flat, no supports)
     carrier    x2   (two identical! supports recommended)
     cap_top    x1   (screw-head side)
     cap_bottom x1   (pilot-hole side)

   ASSEMBLY:
     1. Press a bearing into each planet gear (enters from the
        open face; a lip on the other face retains it).
     2. Press the 3 stub axles of one carrier into the bearing
        inner races, mesh planets onto the sun, then press the
        second carrier (flipped over) onto the other side.
        A drop of glue on the stubs is optional; you can also
        set stub_hole > 0 and run a small screw clean through.
     3. Screw the two caps together through the sun gear bore.
        The carrier rings float around the cap bosses with
        clearance - they are just a safety guide, all the real
        running happens on the planet bearings.

   NOTES:
     - Crossed-helical gears are point-contact: perfect for a
       toy, not for transmitting torque.
     - Keep helix = 45 for perpendicular planets. Other values
       tilt the planet axes (shaft angle = 2*helix); the carrier
       geometry is only computed for 45.
     - The assembly view does not solve tooth phasing, so minor
       visual interpenetration at the mesh is normal.
   ============================================================ */

/* [What to render] */
part = "assembly"; // [assembly, sun, planet, carrier, cap_top, cap_bottom, print]

/* [Gearing] */
// Normal module (tooth size)
gear_mod = 1.2;
// 17+ leaves room for spokes in the sun with default bore/rim
sun_teeth = 17;
planet_teeth = 26;
// 45 = planets exactly perpendicular
helix = 45;
pressure_angle = 20; // [14.5:0.5:30]
// Both gears must be the same hand to mesh at 90 deg
right_hand = true;
// Circumferential backlash per gear, mm
backlash = 0.15;
sun_width = 12;
planet_width = 9;
// Full-profile 45 deg chamfer on the tooth ends, mm (0 = off).
// Tapers the whole tooth (tip AND flanks) at both gear faces.
tooth_chamfer = 0.8;

/* [Planet bearings] */
// Defaults are 608 (8 x 22 x 7). MR105 would be 5,10,4 etc.
pb_bore = 8;
pb_od = 22;
pb_w = 7;
// Oversize added to the bearing pocket diameter (press fit)
pb_od_fit = 0.15;
// Retaining lip depth on the closed face, radial mm
pb_lip = 1.5;
// Undersize on the carrier stub axle (fits bearing bore)
stub_fit = 0.1;
// Through-hole in the stubs for an optional screw (0 = none)
stub_hole = 0;

/* [Spokes] */
// Planet spokes, 0 = solid gear
spoke_count = 5;
// Sun spokes, 0 = solid gear
sun_spoke_count = 4;
spoke_width = 4;
// Radial thickness of the toothed rim (under the root circle)
rim_thickness = 3;
// Wall around the bearing pocket / sun bore
hub_wall = 2.5;
// In-plane fillet radius in the spoke window corners (0 = off)
spoke_fillet = 1.0;
// 45 deg chamfer on the spoke window edges at the faces (0 = off, renders faster)
spoke_chamfer = 0.6;

/* [Carrier] */
plate_t = 3.2;
ring_wall = 3;
arm_w = 6;
pad_d = 14;
pad_t = 3;
// Axial gap between carrier ring and sun gear face
carrier_gap = 1.0;
// Gap between carrier pad and planet gear face
side_gap = 0.6;

/* [Caps and screw] */
cap_d = 22;
cap_h = 8;
// Boss through the sun bore / carrier rings
boss_d = 8;
// Radial clearance carrier ring <-> boss
bush_clr = 0.4;
screw_d = 3;      // M3
screw_head_d = 6.4;
screw_head_h = 3.2;
dimple_depth = 1.4;

/* [Quality] */
$fs = 0.4;
$fa = 3;
// Points per tooth flank
flank_steps = 10;

/* [Assembly view] */
sun_phase = 0;
planet_phase = 7;

// ------------------- derived values -------------------------
hand    = right_hand ? 1 : -1;
mt      = gear_mod / cos(helix);                    // transverse module
alpha_t = atan(tan(pressure_angle) / cos(helix));   // transverse pressure angle
rp_s = mt * sun_teeth / 2;
rp_p = mt * planet_teeth / 2;
ra_s = rp_s + gear_mod;
ra_p = rp_p + gear_mod;
rf_p = rp_p - 1.25 * gear_mod;
a_cd = rp_s + rp_p;                                 // center distance
z0    = sun_width/2 + carrier_gap;                  // carrier plate underside
z_pad = z0 + plate_t + 0.4;                         // cap pad underside
yoff  = planet_width/2 + side_gap + pad_t/2;        // carrier pad mid-plane

echo(str("center distance sun->planet: ", a_cd, " mm"));
echo(str("sun tip dia: ", 2*ra_s, " mm   planet tip dia: ", 2*ra_p, " mm"));
echo(str("overall spinner dia approx: ", 2*(a_cd + ra_p), " mm"));
echo(str("planet-planet center spacing: ", 2*a_cd*sin(60), " mm"));
if (2*a_cd*sin(60) < 2*ra_p*0.85)
    echo("*** WARNING: planets are large vs their spacing - check for planet/planet collision. ***");
if (planet_width < pb_w)
    echo("*** WARNING: planet_width < bearing width. ***");

// ------------------- involute helpers -----------------------
function invdeg(a) = tan(a)*180/PI - a;             // involute fn, degrees
function pol(r, a) = [r*cos(a), r*sin(a)];
// half angular tooth thickness at radius r
function psi(r, rb, ht) =
    ht + invdeg(alpha_t) - invdeg(acos(min(rb/max(r, rb), 1)));

// 2D transverse involute gear profile
module gear2D(z_, bl = 0) {
    rp = mt*z_/2;
    rb = rp*cos(alpha_t);
    ra = rp + gear_mod;
    rf = max(rp - 1.25*gear_mod, 1);
    r0 = max(rb, rf);
    ht = 90/z_ - (bl/2)/rp * 180/PI;                // half thickness @ pitch, deg
    rr = [for (i = [0:flank_steps]) r0 + (ra - r0)*i/flank_steps];
    polygon([
        for (k = [0:z_-1]) let (A = k*360/z_) each concat(
            rf < r0 - 0.02 ? [pol(rf, A - psi(r0, rb, ht))] : [],
            [for (r = rr) pol(r, A - psi(r, rb, ht))],
            [for (i = [flank_steps:-1:0]) pol(rr[i], A + psi(rr[i], rb, ht))],
            rf < r0 - 0.02 ? [pol(rf, A + psi(r0, rb, ht))] : []
        )
    ]);
}

// Helical gear, centered on origin, axis = Z.
// Tooth-end chamfer: the middle of the gear is a plain twisted
// extrusion; each end is a short extrusion that keeps twisting at
// the same rate while scaling the whole profile down, which puts a
// ~45 deg chamfer on the entire tooth profile (tip and flanks).
module helical_gear(z_, w) {
    rp = mt*z_/2;
    ra = rp + gear_mod;
    ch = min(tooth_chamfer, w/3);
    if (ch < 0.05) {
        tw = hand * w * tan(helix) / rp * 180/PI;
        linear_extrude(height = w, center = true, twist = -tw,
                       slices = max(12, ceil(abs(tw)/2)), convexity = 10)
            gear2D(z_, backlash);
    } else {
        wc  = w - 2*ch;                              // core width
        twc = hand * wc * tan(helix) / rp * 180/PI;  // core twist
        twe = hand * ch * tan(helix) / rp * 180/PI;  // end twist
        s   = (ra - ch)/ra;                          // end-face shrink
        union() {
            linear_extrude(height = wc, center = true, twist = -twc,
                           slices = max(12, ceil(abs(twc)/2)), convexity = 10)
                gear2D(z_, backlash);
            // top chamfer section (helix continues, profile shrinks)
            translate([0, 0, wc/2]) rotate([0, 0, twc])
                linear_extrude(height = ch, twist = -twe, scale = s,
                               slices = 4, convexity = 10)
                    gear2D(z_, backlash);
            // bottom chamfer section (180 deg flip preserves the hand;
            // the profile is mirror-symmetric so it lines up exactly)
            translate([0, 0, -wc/2]) rotate([180, 0, 0])
                linear_extrude(height = ch, twist = -twe, scale = s,
                               slices = 4, convexity = 10)
                    gear2D(z_, backlash);
        }
    }
}

// Spoke-window cutter: subtract from a gear of width w.
// Windows get in-plane corner fillets (morphological opening) and
// 45 deg chamfered edges at both faces (minkowski cone wedges).
module spoke_cutter(hub_or, rim_ir, n, w) {
    f = spoke_fillet;
    c = min(spoke_chamfer, w/3);
    module win_raw() {
        difference() {
            circle(r = rim_ir);
            circle(r = hub_or);
            for (i = [0:n-1]) rotate([0, 0, i*360/n])
                translate([0, -spoke_width/2])
                    square([rim_ir + 1, spoke_width]);
        }
    }
    module win2d() {
        if (f > 0.02) offset(r = f) offset(delta = -f) win_raw();
        else win_raw();
    }
    // straight through-cut
    linear_extrude(height = w + 2, center = true, convexity = 10) win2d();
    // chamfer wedges at both faces
    if (c > 0.02)
        for (m = [0, 1]) mirror([0, 0, m])
            translate([0, 0, w/2 - c])
                minkowski() {
                    linear_extrude(height = 0.02) win2d();
                    cylinder(d1 = 0, d2 = 2*c, h = c, $fn = 16);
                }
}

// ------------------- parts ----------------------------------
module sun_gear() {
    bore   = boss_d + 0.3;
    rim_ir = rp_s - 1.25*gear_mod - rim_thickness;
    hub_or = bore/2 + hub_wall;
    ok = sun_spoke_count > 0 && rim_ir > hub_or + 2*spoke_fillet + 0.6;
    if (sun_spoke_count > 0 && !ok)
        echo("*** NOTE: no room for sun spokes (raise sun_teeth or shrink rim/hub/fillet) - sun rendered solid. ***");
    difference() {
        rotate([0, 0, sun_phase]) helical_gear(sun_teeth, sun_width);
        cylinder(d = bore, h = sun_width + 2, center = true);
        if (ok) spoke_cutter(hub_or, rim_ir, sun_spoke_count, sun_width);
    }
}

module planet_gear() {
    rim_ir = rf_p - rim_thickness;
    hub_or = pb_od/2 + pb_od_fit/2 + hub_wall;
    ok = spoke_count > 0 && rim_ir > hub_or + 2*spoke_fillet + 0.6;
    if (spoke_count > 0 && !ok)
        echo("*** NOTE: no room for planet spokes with this bearing/gear combo - planet rendered solid. ***");
    difference() {
        helical_gear(planet_teeth, planet_width);
        // bearing seat: open pocket from +Z face, bearing sits centered
        translate([0, 0, -pb_w/2])
            cylinder(d = pb_od + pb_od_fit, h = planet_width);
        // lip bore on the closed face (retains the bearing)
        cylinder(d = pb_od - 2*pb_lip, h = planet_width + 2, center = true);
        if (ok) spoke_cutter(hub_or, rim_ir, spoke_count, planet_width);
    }
}

module vcyl(x, y, d) {
    translate([x, y, z0]) cylinder(d = d, h = plate_t);
}

module carrier_arm() {
    // where the planet face disc begins (must be at face plane by here)
    x_face = a_cd - ra_p - 0.2;
    // where the arm may start descending below the sun's top face
    x_desc = max(x_face + 1,
                 sqrt(max(pow(ra_s + 0.6, 2) - pow(yoff - pad_t/2, 2), 1)));
    ring_mid = ring_or() - arm_w/2;
    y_att = min(yoff, ring_mid*0.9);
    x_att = sqrt(max(ring_mid*ring_mid - y_att*y_att, 0.25));
    // bridge: hub ring -> planet face plane, stays above the sun
    hull() { vcyl(x_att, y_att, arm_w); vcyl(x_face, yoff, pad_t); }
    // shelf: runs along the face plane until clear of the sun radius
    hull() { vcyl(x_face, yoff, pad_t); vcyl(x_desc, yoff, pad_t); }
    // ribbon: sweeps down beside the planet face to the axle pad
    hull() {
        vcyl(x_desc, yoff, pad_t);
        translate([a_cd, yoff, 0]) rotate([90, 0, 0])
            cylinder(d = pad_d, h = pad_t, center = true);
    }
    // stub axle into the bearing inner race
    stub_d = pb_bore - stub_fit;
    stub_l = yoff - pad_t/2 - 0.3;
    translate([a_cd, yoff - pad_t/2 + 0.01, 0]) rotate([90, 0, 0]) {
        cylinder(d = stub_d, h = stub_l - 0.8);
        translate([0, 0, stub_l - 0.8])
            cylinder(d1 = stub_d, d2 = stub_d - 1.2, h = 0.8); // lead-in
    }
}

function ring_or() = boss_d/2 + bush_clr + ring_wall;

// One carrier plate. Print TWO; the second is the same part
// flipped over (the design is symmetric under a 180 deg flip).
module carrier() {
    ring_ir = boss_d/2 + bush_clr;
    difference() {
        union() {
            translate([0, 0, z0]) difference() {
                cylinder(r = ring_or(), h = plate_t);
                translate([0, 0, -1]) cylinder(r = ring_ir, h = plate_t + 2);
            }
            for (i = [0:2]) rotate([0, 0, i*120]) carrier_arm();
        }
        // re-cut the ring bore (arm roots bulge into it)
        translate([0, 0, z0 - 1]) cylinder(r = ring_ir, h = plate_t + 2);
        // optional through-screw in the stubs
        if (stub_hole > 0)
            for (i = [0:2]) rotate([0, 0, i*120])
                translate([a_cd, 0, 0]) rotate([90, 0, 0])
                    cylinder(d = stub_hole, h = 4*yoff, center = true);
    }
}

module cap(top = true) {
    edge = 1.2;
    dim_d = cap_d*0.72;
    r_dim = (dim_d*dim_d/4 + dimple_depth*dimple_depth) / (2*dimple_depth);
    difference() {
        union() {
            translate([0, 0, 0.15])
                cylinder(d = boss_d, h = z_pad - 0.15);
            translate([0, 0, z_pad]) rotate_extrude(convexity = 4) polygon([
                [0, 0], [cap_d/2, 0], [cap_d/2, cap_h - edge],
                [cap_d/2 - edge, cap_h], [0, cap_h]
            ]);
        }
        // finger dimple
        translate([0, 0, z_pad + cap_h + r_dim - dimple_depth]) sphere(r = r_dim);
        if (top) {
            cylinder(d = screw_d + 0.4, h = 3*z_pad, center = true);
            translate([0, 0, z_pad + cap_h - screw_head_h])
                cylinder(d = screw_head_d, h = cap_h);
        } else {
            translate([0, 0, -1])
                cylinder(d = screw_d*0.85, h = z_pad*0.9); // self-tap pilot
        }
    }
}

// ------------------- assembly & plating ----------------------
module planets_placed() {
    for (i = [0:2])
        rotate([0, 0, i*120])
            translate([a_cd, 0, 0])
                rotate([2*helix, 0, 0])        // 90 deg when helix = 45
                    rotate([0, 0, planet_phase])
                        planet_gear();
}

module assembly() {
    color("MediumPurple") { carrier(); rotate([180, 0, 0]) carrier(); }
    color("LightSeaGreen") sun_gear();
    color("Plum") planets_placed();
    color("MediumSpringGreen") { cap(true); rotate([180, 0, 0]) cap(false); }
}

module print_plate() {
    sp = 2*ra_p + 8;
    translate([0, 0, sun_width/2]) sun_gear();
    for (i = [0:2])
        rotate([0, 0, 30 + i*120]) translate([sp, 0, 0]) rotate([0, 0, -30 - i*120])
            translate([0, 0, planet_width/2]) planet_gear();
    for (s = [-1, 1])
        translate([s*(a_cd + ring_or() + 6), -2.2*sp, pad_d/2]) carrier();
    translate([-0.8*sp, 1.9*sp, z_pad + cap_h]) rotate([180, 0, 0]) cap(true);
    translate([ 0.8*sp, 1.9*sp, z_pad + cap_h]) rotate([180, 0, 0]) cap(false);
}

// ------------------- dispatcher ------------------------------
if      (part == "assembly")   assembly();
else if (part == "sun")        translate([0, 0, sun_width/2]) sun_gear();
else if (part == "planet")     translate([0, 0, planet_width/2]) planet_gear();
else if (part == "carrier")    translate([0, 0, pad_d/2]) carrier();
else if (part == "cap_top")    translate([0, 0, z_pad + cap_h]) rotate([180, 0, 0]) cap(true);
else if (part == "cap_bottom") translate([0, 0, z_pad + cap_h]) rotate([180, 0, 0]) cap(false);
else if (part == "print")      print_plate();
