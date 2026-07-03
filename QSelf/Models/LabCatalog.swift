import Foundation

// NOTE: AppTier enum is defined in QS_RegimenCatalog.swift — same module, no import needed.

// MARK: - Lab Category

enum LabCategory: String, Codable, CaseIterable {
    case hematology     = "Hematology"
    case metabolic      = "Metabolic"
    case hormonal       = "Hormonal"
    case cardiovascular = "Cardiovascular"
    case inflammatory   = "Inflammatory"
    case thyroid        = "Thyroid"
    case nutritional    = "Nutritional"
    case other          = "Other"
}

// MARK: - LabTest

/// One individual biomarker within a panel.
/// Reference ranges are provided for males/general; femaleRef* overrides where values differ meaningfully.
struct LabTest: Identifiable {
    let id: String            // stable snake_case key, unique across entire catalog
    let name: String
    let abbreviation: String  // short label used on charts and result rows
    let unit: String
    let refRangeLow: Double?  // male / general lower bound; nil = no lower bound
    let refRangeHigh: Double? // male / general upper bound; nil = no upper bound
    let femaleRefLow: Double? // nil = use refRangeLow
    let femaleRefHigh: Double? // nil = use refRangeHigh
    let notes: String         // clinical context shown in the detail view
}

// MARK: - LabPanel

/// A named grouping of tests that are typically ordered and drawn together.
/// When the user logs a draw, they pick panels to pre-populate the test rows.
struct LabPanel: Identifiable {
    let id: String
    let name: String
    let category: LabCategory
    let tier: AppTier
    let description: String
    let tests: [LabTest]
    let orderingNotes: String  // prep instructions shown before the user adds the draw
}

// MARK: - LabCatalog

struct LabCatalog {

    // MARK: Free panels (15)

    static let freePanels: [LabPanel] = [

        // ── 1. Complete Blood Count ───────────────────────────────────────────
        LabPanel(
            id: "cbc",
            name: "Complete Blood Count (CBC)",
            category: .hematology,
            tier: .free,
            description: "Evaluates red cells, white cells, and platelets. The most commonly ordered panel; essential baseline for anyone on TRT due to hematocrit monitoring.",
            tests: [
                LabTest(id: "cbc_wbc",   name: "White Blood Cells",                  abbreviation: "WBC",   unit: "K/µL",  refRangeLow: 4.5,  refRangeHigh: 11.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Elevated in infection or inflammation; low may indicate immune suppression"),
                LabTest(id: "cbc_rbc",   name: "Red Blood Cells",                    abbreviation: "RBC",   unit: "M/µL",  refRangeLow: 4.5,  refRangeHigh: 5.9,  femaleRefLow: 4.0, femaleRefHigh: 5.2, notes: "Oxygen-carrying cells. Elevated in polycythemia; low in anemia"),
                LabTest(id: "cbc_hgb",   name: "Hemoglobin",                         abbreviation: "Hgb",   unit: "g/dL",  refRangeLow: 13.5, refRangeHigh: 17.5, femaleRefLow: 12.0, femaleRefHigh: 15.5, notes: "Primary O2-carrying protein. Key TRT safety marker — target below 17.5"),
                LabTest(id: "cbc_hct",   name: "Hematocrit",                         abbreviation: "Hct",   unit: "%",     refRangeLow: 41.0, refRangeHigh: 53.0, femaleRefLow: 36.0, femaleRefHigh: 46.0, notes: "% of blood that is red cells. Monitor closely on TRT; therapeutic phlebotomy if >52–54%"),
                LabTest(id: "cbc_mcv",   name: "Mean Corpuscular Volume",            abbreviation: "MCV",   unit: "fL",    refRangeLow: 80.0, refRangeHigh: 100.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Red cell size. Low = iron deficiency; high = B12 or folate deficiency"),
                LabTest(id: "cbc_mch",   name: "Mean Corpuscular Hemoglobin",        abbreviation: "MCH",   unit: "pg",    refRangeLow: 27.0, refRangeHigh: 33.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Average hemoglobin mass per red cell"),
                LabTest(id: "cbc_mchc",  name: "MCHC",                               abbreviation: "MCHC",  unit: "g/dL",  refRangeLow: 32.0, refRangeHigh: 36.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Hemoglobin concentration within red cells"),
                LabTest(id: "cbc_plt",   name: "Platelets",                          abbreviation: "PLT",   unit: "K/µL",  refRangeLow: 150.0, refRangeHigh: 400.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Clotting cells. Very high or low warrants follow-up"),
                LabTest(id: "cbc_neut",  name: "Neutrophils",                        abbreviation: "Neut%", unit: "%",     refRangeLow: 40.0, refRangeHigh: 70.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Primary infection-fighting white cells"),
                LabTest(id: "cbc_lymph", name: "Lymphocytes",                        abbreviation: "Lymph%", unit: "%",    refRangeLow: 20.0, refRangeHigh: 40.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Immune cells. Mildly low on exogenous testosterone is common"),
            ],
            orderingNotes: "No fasting required. Results typically available within 24 hours."
        ),

        // ── 2. Comprehensive Metabolic Panel ─────────────────────────────────
        LabPanel(
            id: "cmp",
            name: "Comprehensive Metabolic Panel (CMP)",
            category: .metabolic,
            tier: .free,
            description: "14-test panel covering kidney function, liver enzymes, electrolytes, and blood glucose. Fundamental baseline for any health optimization protocol.",
            tests: [
                LabTest(id: "cmp_glucose",    name: "Glucose",                        abbreviation: "Gluc",    unit: "mg/dL",          refRangeLow: 70.0,  refRangeHigh: 99.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Fasting glucose. 100–125 = prediabetes; ≥126 = diabetes"),
                LabTest(id: "cmp_bun",        name: "Blood Urea Nitrogen",            abbreviation: "BUN",     unit: "mg/dL",          refRangeLow: 7.0,   refRangeHigh: 20.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Kidney waste product. Elevated with dehydration or reduced kidney function"),
                LabTest(id: "cmp_creatinine", name: "Creatinine",                     abbreviation: "Creat",   unit: "mg/dL",          refRangeLow: 0.7,   refRangeHigh: 1.2,   femaleRefLow: 0.5, femaleRefHigh: 1.0, notes: "Kidney filtration marker. Can be elevated with high muscle mass independent of kidney disease"),
                LabTest(id: "cmp_egfr",       name: "eGFR",                           abbreviation: "eGFR",    unit: "mL/min/1.73m²",  refRangeLow: 60.0,  refRangeHigh: 120.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Estimated kidney filtration rate. <60 suggests possible kidney disease"),
                LabTest(id: "cmp_sodium",     name: "Sodium",                         abbreviation: "Na",      unit: "mEq/L",          refRangeLow: 136.0, refRangeHigh: 145.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Electrolyte reflecting hydration and kidney regulation"),
                LabTest(id: "cmp_potassium",  name: "Potassium",                      abbreviation: "K",       unit: "mEq/L",          refRangeLow: 3.5,   refRangeHigh: 5.1,   femaleRefLow: nil, femaleRefHigh: nil, notes: "Critical for heart rhythm. Very high or low is dangerous"),
                LabTest(id: "cmp_chloride",   name: "Chloride",                       abbreviation: "Cl",      unit: "mEq/L",          refRangeLow: 98.0,  refRangeHigh: 107.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Electrolyte balance marker"),
                LabTest(id: "cmp_co2",        name: "Carbon Dioxide (Bicarbonate)",   abbreviation: "CO2",     unit: "mEq/L",          refRangeLow: 22.0,  refRangeHigh: 29.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Acid–base balance"),
                LabTest(id: "cmp_calcium",    name: "Calcium",                        abbreviation: "Ca",      unit: "mg/dL",          refRangeLow: 8.6,   refRangeHigh: 10.2,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Bone, muscle, and nerve function"),
                LabTest(id: "cmp_protein",    name: "Total Protein",                  abbreviation: "TP",      unit: "g/dL",           refRangeLow: 6.3,   refRangeHigh: 8.2,   femaleRefLow: nil, femaleRefHigh: nil, notes: "Reflects nutritional status and liver/kidney function"),
                LabTest(id: "cmp_albumin",    name: "Albumin",                        abbreviation: "Alb",     unit: "g/dL",           refRangeLow: 3.5,   refRangeHigh: 5.0,   femaleRefLow: nil, femaleRefHigh: nil, notes: "Main blood protein. Low = poor nutrition or liver dysfunction"),
                LabTest(id: "cmp_bilirubin",  name: "Total Bilirubin",                abbreviation: "T.Bili",  unit: "mg/dL",          refRangeLow: 0.1,   refRangeHigh: 1.2,   femaleRefLow: nil, femaleRefHigh: nil, notes: "Liver waste product. Elevated in liver disease or hemolysis"),
                LabTest(id: "cmp_alt",        name: "Alanine Aminotransferase",       abbreviation: "ALT",     unit: "U/L",            refRangeLow: 7.0,   refRangeHigh: 56.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Most liver-specific enzyme. Elevated by alcohol, medications, and TRT"),
                LabTest(id: "cmp_ast",        name: "Aspartate Aminotransferase",     abbreviation: "AST",     unit: "U/L",            refRangeLow: 10.0,  refRangeHigh: 40.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Liver and muscle enzyme. Can be transiently elevated after intense exercise"),
                LabTest(id: "cmp_alp",        name: "Alkaline Phosphatase",           abbreviation: "ALP",     unit: "U/L",            refRangeLow: 44.0,  refRangeHigh: 147.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Liver and bone marker"),
            ],
            orderingNotes: "Fast for 8–12 hours for accurate glucose and BUN readings."
        ),

        // ── 3. Lipid Panel ────────────────────────────────────────────────────
        LabPanel(
            id: "lipid",
            name: "Lipid Panel",
            category: .cardiovascular,
            tier: .free,
            description: "Measures cholesterol fractions and triglycerides to assess cardiovascular disease risk. Recommended annually for adults.",
            tests: [
                LabTest(id: "lip_tc",     name: "Total Cholesterol",   abbreviation: "TC",      unit: "mg/dL", refRangeLow: 100.0, refRangeHigh: 199.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "<200 desirable; 200–239 borderline high; ≥240 high"),
                LabTest(id: "lip_ldl",    name: "LDL Cholesterol",     abbreviation: "LDL",     unit: "mg/dL", refRangeLow: 0.0,   refRangeHigh: 99.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "'Bad' cholesterol. <100 optimal; <70 for high CVD risk individuals"),
                LabTest(id: "lip_hdl",    name: "HDL Cholesterol",     abbreviation: "HDL",     unit: "mg/dL", refRangeLow: 40.0,  refRangeHigh: 90.0,  femaleRefLow: 50.0, femaleRefHigh: 90.0, notes: "'Good' cholesterol. >60 protective; <40 (men) or <50 (women) increases CVD risk"),
                LabTest(id: "lip_tg",     name: "Triglycerides",       abbreviation: "TG",      unit: "mg/dL", refRangeLow: 0.0,   refRangeHigh: 149.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "<150 normal. Elevated by sugar, alcohol, and refined carbs. Fasting-sensitive"),
                LabTest(id: "lip_nonhdl", name: "Non-HDL Cholesterol", abbreviation: "Non-HDL", unit: "mg/dL", refRangeLow: 0.0,   refRangeHigh: 129.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Total cholesterol minus HDL. Better CVD predictor than LDL-C alone"),
            ],
            orderingNotes: "Fast for 9–12 hours. Triglycerides are particularly sensitive to recent food intake."
        ),

        // ── 4. Thyroid Panel ──────────────────────────────────────────────────
        LabPanel(
            id: "thyroid_basic",
            name: "Thyroid Panel",
            category: .thyroid,
            tier: .free,
            description: "Assesses thyroid gland function — the primary driver of metabolic rate, energy levels, mood, and body composition.",
            tests: [
                LabTest(id: "thy_tsh", name: "Thyroid Stimulating Hormone", abbreviation: "TSH", unit: "mIU/L",  refRangeLow: 0.4, refRangeHigh: 4.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Primary thyroid screen. High = hypothyroid; low = hyperthyroid. Optimal often cited as 1.0–2.5"),
                LabTest(id: "thy_ft4", name: "Free T4 (Thyroxine)",         abbreviation: "FT4", unit: "ng/dL",  refRangeLow: 0.8, refRangeHigh: 1.8,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Inactive thyroid hormone; converted to active T3 in peripheral tissues"),
                LabTest(id: "thy_ft3", name: "Free T3 (Triiodothyronine)",  abbreviation: "FT3", unit: "pg/mL",  refRangeLow: 2.3, refRangeHigh: 4.2,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Active thyroid hormone. Most relevant for symptom correlation; low despite normal TSH is common"),
            ],
            orderingNotes: "No special preparation. Draw at the same time of day for valid serial comparisons."
        ),

        // ── 5. Hemoglobin A1c ─────────────────────────────────────────────────
        LabPanel(
            id: "hba1c",
            name: "Hemoglobin A1c (HbA1c)",
            category: .metabolic,
            tier: .free,
            description: "Reflects average blood glucose over the past 2–3 months. Primary screen for diabetes and metabolic health. More stable than a single fasting glucose reading.",
            tests: [
                LabTest(id: "hba1c_val", name: "Hemoglobin A1c", abbreviation: "HbA1c", unit: "%", refRangeLow: 4.0, refRangeHigh: 5.6, femaleRefLow: nil, femaleRefHigh: nil, notes: "<5.7% normal; 5.7–6.4% prediabetes; ≥6.5% diabetes. Longevity sweet spot often cited as 4.8–5.3%"),
            ],
            orderingNotes: "No fasting required. Can be drawn any time of day."
        ),

        // ── 6. Total Testosterone ─────────────────────────────────────────────
        LabPanel(
            id: "total_testosterone",
            name: "Total Testosterone",
            category: .hormonal,
            tier: .free,
            description: "Measures all circulating testosterone. Essential baseline for anyone monitoring hormonal health or on TRT.",
            tests: [
                LabTest(id: "tt_val", name: "Total Testosterone", abbreviation: "Total T", unit: "ng/dL", refRangeLow: 300.0, refRangeHigh: 1000.0, femaleRefLow: 15.0, femaleRefHigh: 70.0, notes: "Males: lab range 300–1000; optimized TRT often targets 700–1000. Levels fall ~35% through the day — always draw in the morning"),
            ],
            orderingNotes: "Draw between 7 AM and 10 AM. Levels peak in the morning and fall significantly by afternoon."
        ),

        // ── 7. Vitamin D ──────────────────────────────────────────────────────
        LabPanel(
            id: "vitamin_d",
            name: "Vitamin D (25-OH)",
            category: .nutritional,
            tier: .free,
            description: "Measures circulating vitamin D stores. Deficiency is among the most common nutrient insufficiencies and affects immunity, mood, bone density, and testosterone production.",
            tests: [
                LabTest(id: "vitd_val", name: "25-OH Vitamin D", abbreviation: "Vit D", unit: "ng/mL", refRangeLow: 30.0, refRangeHigh: 100.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "<20 deficient; 20–29 insufficient; 30–100 sufficient. Many longevity-focused clinicians target 50–80 ng/mL"),
            ],
            orderingNotes: "No special preparation. Levels vary with sun exposure and supplementation."
        ),

        // ── 8. Iron Studies & Ferritin ────────────────────────────────────────
        LabPanel(
            id: "iron_studies",
            name: "Iron Studies & Ferritin",
            category: .hematology,
            tier: .free,
            description: "Assesses iron stores and transport capacity. Iron is critical for energy, endurance, cognitive function, and oxygen delivery. Ferritin can be low even when CBC looks normal.",
            tests: [
                LabTest(id: "iron_ferritin", name: "Ferritin",                   abbreviation: "Ferritin", unit: "ng/mL",  refRangeLow: 24.0,  refRangeHigh: 336.0, femaleRefLow: 11.0,  femaleRefHigh: 307.0, notes: "Iron storage protein. Optimal for athletes often >50. Very high (>300) may reflect inflammation rather than iron overload"),
                LabTest(id: "iron_serum",    name: "Serum Iron",                  abbreviation: "Fe",       unit: "µg/dL",  refRangeLow: 60.0,  refRangeHigh: 170.0, femaleRefLow: nil,   femaleRefHigh: nil,   notes: "Circulating iron. Highly variable with time of day and recent meals — interpret alongside TIBC and ferritin"),
                LabTest(id: "iron_tibc",     name: "Total Iron-Binding Capacity", abbreviation: "TIBC",     unit: "µg/dL",  refRangeLow: 250.0, refRangeHigh: 370.0, femaleRefLow: nil,   femaleRefHigh: nil,   notes: "Reflects transferrin capacity. High TIBC = iron deficiency"),
                LabTest(id: "iron_sat",      name: "Transferrin Saturation",      abbreviation: "TSAT",     unit: "%",      refRangeLow: 20.0,  refRangeHigh: 50.0,  femaleRefLow: nil,   femaleRefHigh: nil,   notes: "% of transferrin bound to iron. <20% = deficiency; >50% = possible overload or hemochromatosis"),
            ],
            orderingNotes: "Draw in the morning before eating. Serum iron fluctuates significantly with meals."
        ),

        // ── 9. Fasting Glucose & Insulin ─────────────────────────────────────
        LabPanel(
            id: "glucose_insulin",
            name: "Fasting Glucose & Insulin",
            category: .metabolic,
            tier: .free,
            description: "Detects insulin resistance earlier than HbA1c alone. HOMA-IR — calculated as (fasting glucose × fasting insulin) ÷ 405 — is the key output.",
            tests: [
                LabTest(id: "gi_glucose", name: "Fasting Glucose", abbreviation: "FBG",     unit: "mg/dL",    refRangeLow: 70.0, refRangeHigh: 99.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "100–125 = prediabetes. Must be a true 8–12 hour fast"),
                LabTest(id: "gi_insulin", name: "Fasting Insulin", abbreviation: "Insulin",  unit: "µIU/mL",   refRangeLow: 2.0,  refRangeHigh: 20.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Lab range is wide; optimal often <6. HOMA-IR = (glucose × insulin) / 405; target <1.5"),
            ],
            orderingNotes: "Strict 8–12 hour fast required. Both values must be drawn simultaneously for valid HOMA-IR calculation."
        ),

        // ── 10. hsCRP ─────────────────────────────────────────────────────────
        LabPanel(
            id: "hscrp",
            name: "High-Sensitivity CRP (hsCRP)",
            category: .inflammatory,
            tier: .free,
            description: "Sensitive marker of systemic inflammation. Independently predicts cardiovascular disease and all-cause mortality even when cholesterol is normal.",
            tests: [
                LabTest(id: "hscrp_val", name: "hsCRP", abbreviation: "hsCRP", unit: "mg/L", refRangeLow: 0.0, refRangeHigh: 1.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "<1.0 mg/L low CVD risk; 1.0–3.0 moderate; >3.0 high risk. Longevity target often <0.5. Exclude acute illness or injury when interpreting"),
            ],
            orderingNotes: "Do not test during active infection or recent injury — hsCRP will be falsely elevated."
        ),

        // ── 11. Free Testosterone & SHBG ─────────────────────────────────────
        LabPanel(
            id: "free_t_shbg",
            name: "Free Testosterone & SHBG",
            category: .hormonal,
            tier: .free,
            description: "Measures bioavailable testosterone and the binding protein that controls it. Free T is often more clinically meaningful than total T — especially when SHBG is high.",
            tests: [
                LabTest(id: "ft_free_t",     name: "Free Testosterone",       abbreviation: "Free T",     unit: "ng/dL",   refRangeLow: 9.0,   refRangeHigh: 30.0,   femaleRefLow: 0.6,  femaleRefHigh: 3.8,  notes: "Unbound, biologically active fraction. Can be low even when total T is normal due to elevated SHBG"),
                LabTest(id: "ft_shbg",        name: "SHBG",                    abbreviation: "SHBG",       unit: "nmol/L",  refRangeLow: 10.0,  refRangeHigh: 57.0,   femaleRefLow: 18.0, femaleRefHigh: 114.0, notes: "Binds and inactivates testosterone. Raised by alcohol, thyroid disease, and aging; lowered by obesity and insulin resistance"),
                LabTest(id: "ft_bioavail_t",  name: "Bioavailable Testosterone", abbreviation: "Bioavail T", unit: "ng/dL",  refRangeLow: 131.0, refRangeHigh: 682.0,  femaleRefLow: 0.5,  femaleRefHigh: 8.5,  notes: "Free T plus albumin-bound T. Most complete picture of androgenic activity"),
            ],
            orderingNotes: "Draw between 7 AM and 10 AM alongside total testosterone for a complete hormonal picture."
        ),

        // ── 12. Estradiol ─────────────────────────────────────────────────────
        LabPanel(
            id: "estradiol",
            name: "Estradiol (E2)",
            category: .hormonal,
            tier: .free,
            description: "The primary estrogen. In men on TRT, testosterone aromatizes to estradiol — both excessively high and low E2 cause symptoms affecting libido, mood, bone density, and cardiovascular health.",
            tests: [
                LabTest(id: "e2_val", name: "Estradiol", abbreviation: "E2", unit: "pg/mL", refRangeLow: 10.0, refRangeHigh: 40.0, femaleRefLow: 15.0, femaleRefHigh: 350.0, notes: "Males on TRT: symptoms emerge when <15 (low) or >45 (high). Optimal mid-range often 20–30 pg/mL"),
            ],
            orderingNotes: "Males should specify 'Estradiol Sensitive' (LC/MS method) — standard immunoassay is inaccurate at male-range concentrations."
        ),

        // ── 13. PSA ───────────────────────────────────────────────────────────
        LabPanel(
            id: "psa",
            name: "PSA (Prostate-Specific Antigen)",
            category: .other,
            tier: .free,
            description: "Prostate health marker. Annual monitoring is recommended for men on TRT. TRT does not cause prostate cancer but may unmask pre-existing disease.",
            tests: [
                LabTest(id: "psa_total", name: "PSA Total", abbreviation: "PSA", unit: "ng/mL", refRangeLow: 0.0, refRangeHigh: 4.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "<4.0 generally normal; age-adjusted thresholds apply. A rapid rise (velocity >0.75 ng/mL/year) is as important as the absolute value"),
            ],
            orderingNotes: "Avoid ejaculation, vigorous cycling, and prostate stimulation for 48 hours before draw. Prostatitis or BPH can elevate PSA without cancer."
        ),

        // ── 14. Uric Acid ─────────────────────────────────────────────────────
        LabPanel(
            id: "uric_acid",
            name: "Uric Acid",
            category: .metabolic,
            tier: .free,
            description: "Byproduct of purine metabolism. Elevated levels cause gout and are strongly associated with metabolic syndrome, hypertension, and cardiovascular risk.",
            tests: [
                LabTest(id: "ua_val", name: "Uric Acid", abbreviation: "UA", unit: "mg/dL", refRangeLow: 3.5, refRangeHigh: 7.2, femaleRefLow: 2.6, femaleRefHigh: 6.0, notes: "Gout threshold >7.0 (men) or >6.0 (women). Longevity-focused target often <5.5. Fructose, alcohol, red meat, and dehydration raise levels"),
            ],
            orderingNotes: "No special preparation required, though recent high-purine meals (organ meat, shellfish) may transiently elevate results."
        ),

        // ── 15. Prolactin ─────────────────────────────────────────────────────
        LabPanel(
            id: "prolactin",
            name: "Prolactin",
            category: .hormonal,
            tier: .free,
            description: "Pituitary hormone that suppresses testosterone and libido when elevated. Chronically high levels may indicate a pituitary adenoma requiring imaging.",
            tests: [
                LabTest(id: "prl_val", name: "Prolactin", abbreviation: "PRL", unit: "ng/mL", refRangeLow: 2.0, refRangeHigh: 18.0, femaleRefLow: 2.0, femaleRefHigh: 29.0, notes: "In men: elevated prolactin causes low libido, erectile dysfunction, and testosterone suppression. Markedly high levels (>50) warrant MRI pituitary"),
            ],
            orderingNotes: "Draw at least 1 hour after waking. Avoid sexual activity, intense exercise, and stress for 1 hour before draw — all transiently raise prolactin."
        ),
    ]

    // MARK: Pro panels (10)

    static let proPanels: [LabPanel] = [

        // ── 16. LH & FSH ──────────────────────────────────────────────────────
        LabPanel(
            id: "lh_fsh",
            name: "LH & FSH",
            category: .hormonal,
            tier: .pro,
            description: "Pituitary gonadotropins that signal the testes or ovaries to produce hormones. Essential for distinguishing primary from secondary hypogonadism and assessing fertility on or off TRT.",
            tests: [
                LabTest(id: "lhfsh_lh",  name: "Luteinizing Hormone",     abbreviation: "LH",  unit: "mIU/mL", refRangeLow: 1.7, refRangeHigh: 8.6,  femaleRefLow: 2.4, femaleRefHigh: 12.6, notes: "Signals testosterone production. Suppressed to near-zero on exogenous testosterone. Low LH + low T = secondary hypogonadism"),
                LabTest(id: "lhfsh_fsh", name: "Follicle Stimulating Hormone", abbreviation: "FSH", unit: "mIU/mL", refRangeLow: 1.5, refRangeHigh: 12.4, femaleRefLow: 3.5, femaleRefHigh: 12.5, notes: "Signals sperm/egg production. Used to assess fertility impact of TRT. Suppressed by exogenous androgens"),
            ],
            orderingNotes: "Morning draw preferred. On TRT, LH and FSH will be suppressed — this is expected, not a lab error."
        ),

        // ── 17. DHEA-S & Morning Cortisol ────────────────────────────────────
        LabPanel(
            id: "dheas_cortisol",
            name: "DHEA-S & Morning Cortisol",
            category: .hormonal,
            tier: .pro,
            description: "Adrenal hormones reflecting stress response and androgenic reserve. DHEA-S is the most abundant circulating steroid and declines with age; cortisol reflects HPA axis function.",
            tests: [
                LabTest(id: "dc_dheas",    name: "DHEA-Sulfate",      abbreviation: "DHEA-S",  unit: "µg/dL",  refRangeLow: 106.0, refRangeHigh: 464.0, femaleRefLow: 45.0,  femaleRefHigh: 320.0, notes: "Precursor to testosterone and estrogen. Declines ~2% per year after age 25. Supplementation may partially restore levels"),
                LabTest(id: "dc_cortisol", name: "Morning Cortisol",  abbreviation: "Cortisol", unit: "µg/dL",  refRangeLow: 6.0,   refRangeHigh: 23.0,  femaleRefLow: nil,   femaleRefHigh: nil,   notes: "Stress hormone. Chronically elevated = HPA dysfunction, muscle wasting, disrupted sleep. Low = adrenal insufficiency requiring evaluation"),
            ],
            orderingNotes: "Draw between 7 AM and 9 AM strictly — cortisol follows a strong diurnal rhythm and results are only meaningful early morning."
        ),

        // ── 18. IGF-1 ─────────────────────────────────────────────────────────
        LabPanel(
            id: "igf1",
            name: "IGF-1 (Growth Hormone Surrogate)",
            category: .hormonal,
            tier: .pro,
            description: "IGF-1 is produced by the liver in response to growth hormone. It is the best practical proxy for GH status and is relevant to body composition, recovery rate, and longevity signaling.",
            tests: [
                LabTest(id: "igf1_val", name: "IGF-1", abbreviation: "IGF-1", unit: "ng/mL", refRangeLow: 115.0, refRangeHigh: 307.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Reference range is strongly age-dependent — values decline with age. Elevated by GH-releasing peptides (Ipamorelin, CJC-1295). Very high IGF-1 may promote cancer growth"),
            ],
            orderingNotes: "No fasting required. Withhold GH-releasing peptides for at least 72 hours before draw for an accurate baseline."
        ),

        // ── 19. Homocysteine ──────────────────────────────────────────────────
        LabPanel(
            id: "homocysteine",
            name: "Homocysteine",
            category: .cardiovascular,
            tier: .pro,
            description: "Amino acid marker of B-vitamin status and methylation efficiency. Elevated homocysteine is an independent cardiovascular risk factor and is associated with cognitive decline and dementia.",
            tests: [
                LabTest(id: "hcy_val", name: "Homocysteine", abbreviation: "Hcy", unit: "µmol/L", refRangeLow: 0.0, refRangeHigh: 15.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Lab reference <15; longevity target <10; optimal often <7. Elevated by B12 or folate deficiency and MTHFR variants. Lowered with B12, methylfolate, and B6"),
            ],
            orderingNotes: "Fast for 8–12 hours. Methionine-rich meals (animal protein) can transiently elevate levels."
        ),

        // ── 20. ApoB & Lp(a) ─────────────────────────────────────────────────
        LabPanel(
            id: "apob_lpa",
            name: "ApoB & Lp(a)",
            category: .cardiovascular,
            tier: .pro,
            description: "Advanced cardiovascular risk markers not captured by standard lipid panels. ApoB counts all atherogenic particles; Lp(a) is a genetically-determined, largely diet-resistant risk factor.",
            tests: [
                LabTest(id: "apob_val", name: "Apolipoprotein B", abbreviation: "ApoB", unit: "mg/dL",  refRangeLow: 0.0,  refRangeHigh: 100.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Better CVD predictor than LDL-C. Each atherogenic particle carries one ApoB molecule. Target <80 mg/dL (low risk); <60 (very low risk)"),
                LabTest(id: "lpa_val",  name: "Lipoprotein(a)",   abbreviation: "Lp(a)", unit: "nmol/L", refRangeLow: 0.0, refRangeHigh: 75.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Genetically determined — diet and lifestyle have minimal effect. >75 nmol/L significantly increases ASCVD and aortic stenosis risk. Test once; rarely changes"),
            ],
            orderingNotes: "No fasting required. Lp(a) needs to be tested only once in most people as it is genetically set."
        ),

        // ── 21. Advanced Lipid NMR Panel ──────────────────────────────────────
        LabPanel(
            id: "nmr_lipid",
            name: "Advanced Lipid NMR Panel",
            category: .cardiovascular,
            tier: .pro,
            description: "Nuclear Magnetic Resonance spectroscopy measures LDL particle number and size. Small dense LDL particles are far more atherogenic than large buoyant ones — this is often missed by a standard lipid panel.",
            tests: [
                LabTest(id: "nmr_ldlp",    name: "LDL Particle Number", abbreviation: "LDL-P",     unit: "nmol/L", refRangeLow: 0.0,   refRangeHigh: 1000.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Total atherogenic LDL particles. >1000 = elevated risk; <700 optimal. More predictive than LDL-C in insulin-resistant individuals"),
                LabTest(id: "nmr_sldl",    name: "Small LDL Particles",  abbreviation: "Small LDL-P", unit: "nmol/L", refRangeLow: 0.0, refRangeHigh: 527.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Dense particles that penetrate arterial walls more easily. Driven by carbohydrate intake and insulin resistance"),
                LabTest(id: "nmr_ldlsize", name: "LDL Particle Size",    abbreviation: "LDL Size",   unit: "nm",     refRangeLow: 20.6, refRangeHigh: 23.0,   femaleRefLow: nil, femaleRefHigh: nil, notes: "Pattern A (>20.6 nm) = large buoyant = lower risk. Pattern B (<20.6 nm) = small dense = higher risk"),
                LabTest(id: "nmr_hdlp",    name: "HDL Particle Number",  abbreviation: "HDL-P",      unit: "µmol/L", refRangeLow: 30.5, refRangeHigh: 40.0,   femaleRefLow: nil, femaleRefHigh: nil, notes: "Higher particle count improves reverse cholesterol transport"),
            ],
            orderingNotes: "Fast for 9–12 hours. Order as 'NMR LipoProfile' (LabCorp) or 'Lipoprotein Fractionation' (Quest)."
        ),

        // ── 22. Omega-3 Index ─────────────────────────────────────────────────
        LabPanel(
            id: "omega3",
            name: "Omega-3 Index",
            category: .cardiovascular,
            tier: .pro,
            description: "Measures EPA and DHA content of red blood cell membranes — a 3–4 month average of omega-3 status. One of the strongest predictors of cardiovascular and all-cause mortality.",
            tests: [
                LabTest(id: "o3_index", name: "Omega-3 Index", abbreviation: "O3 Index", unit: "%", refRangeLow: 8.0, refRangeHigh: 12.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "<4% = very high CVD risk; 4–8% intermediate; >8% low risk. Most Western diets produce 4–5% — difficult to exceed 8% without supplementation"),
                LabTest(id: "o3_epa",   name: "EPA",           abbreviation: "EPA",      unit: "%", refRangeLow: 1.0, refRangeHigh: 4.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Eicosapentaenoic acid. Anti-inflammatory; primary cardiovascular benefit"),
                LabTest(id: "o3_dha",   name: "DHA",           abbreviation: "DHA",      unit: "%", refRangeLow: 3.5, refRangeHigh: 8.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Docosahexaenoic acid. Primary structural fat in brain tissue; critical for cognitive function"),
            ],
            orderingNotes: "No fasting required. Reflects a ~120-day average — short-term supplement changes will not show immediately."
        ),

        // ── 23. Heavy Metals Panel ────────────────────────────────────────────
        LabPanel(
            id: "heavy_metals",
            name: "Heavy Metals Panel",
            category: .other,
            tier: .pro,
            description: "Screens for toxic metal burden from environmental and dietary exposure. Lead, mercury, arsenic, and cadmium are the most clinically relevant for most adults in Western countries.",
            tests: [
                LabTest(id: "hm_lead",    name: "Blood Lead",             abbreviation: "Pb",  unit: "µg/dL",  refRangeLow: 0.0, refRangeHigh: 3.5,  femaleRefLow: nil, femaleRefHigh: nil, notes: "CDC adult action level: 3.5 µg/dL. Sources: old paint, imported goods, some supplements. No safe level established"),
                LabTest(id: "hm_mercury", name: "Blood Mercury",          abbreviation: "Hg",  unit: "µg/L",   refRangeLow: 0.0, refRangeHigh: 10.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Primary source: large fish (tuna, swordfish, king mackerel). Neurological toxin at elevated levels. Optimal often cited as <5 µg/L"),
                LabTest(id: "hm_arsenic", name: "Urine Arsenic (Total)",  abbreviation: "As",  unit: "µg/L",   refRangeLow: 0.0, refRangeHigh: 35.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Sources: rice, groundwater, some pesticides. Urine is preferred over blood for chronic exposure. Avoid seafood 48h before to distinguish organic from inorganic arsenic"),
                LabTest(id: "hm_cadmium", name: "Blood Cadmium",          abbreviation: "Cd",  unit: "µg/L",   refRangeLow: 0.0, refRangeHigh: 2.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Primary source: cigarette smoke and contaminated food. Accumulates in kidneys over decades"),
            ],
            orderingNotes: "Avoid seafood for 48 hours before arsenic testing. Mercury reflects recent exposure (past few months)."
        ),

        // ── 24. Methylation Panel ─────────────────────────────────────────────
        LabPanel(
            id: "methylation",
            name: "Methylation Panel (B12, Folate, Homocysteine)",
            category: .nutritional,
            tier: .pro,
            description: "Assesses the methylation cycle — critical for DNA repair, neurotransmitter synthesis, detoxification, and cardiovascular health. Often disrupted by MTHFR gene variants.",
            tests: [
                LabTest(id: "meth_b12",        name: "Vitamin B12",     abbreviation: "B12",       unit: "pg/mL",  refRangeLow: 200.0, refRangeHigh: 900.0,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Lab low of 200 is too conservative for neurological health. Many practitioners target >500. Vegans and metformin users are high-risk for deficiency"),
                LabTest(id: "meth_folate",      name: "Serum Folate",    abbreviation: "Folate",    unit: "ng/mL",  refRangeLow: 3.1,   refRangeHigh: 17.5,   femaleRefLow: nil, femaleRefHigh: nil, notes: "B9 vitamin. Essential for DNA synthesis and methylation. Use methylfolate form if MTHFR positive"),
                LabTest(id: "meth_rbc_folate",  name: "RBC Folate",      abbreviation: "RBC Folate", unit: "ng/mL", refRangeLow: 400.0, refRangeHigh: 1500.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Long-term folate status (3–4 month average). More stable and reliable than serum folate"),
                LabTest(id: "meth_hcy",         name: "Homocysteine",    abbreviation: "Hcy",       unit: "µmol/L", refRangeLow: 0.0,   refRangeHigh: 15.0,   femaleRefLow: nil, femaleRefHigh: nil, notes: "Functional indicator of methylation cycle efficiency. Elevated despite adequate B12/folate suggests MTHFR polymorphism. Target <10; optimal <7"),
            ],
            orderingNotes: "Fast for 8–12 hours. Draw before taking B-vitamin supplements that day for an accurate baseline reading."
        ),

        // ── 25. Full Thyroid Antibody Panel ───────────────────────────────────
        LabPanel(
            id: "thyroid_antibody",
            name: "Full Thyroid Antibody Panel",
            category: .thyroid,
            tier: .pro,
            description: "Detects autoimmune thyroid disease — Hashimoto's thyroiditis and Graves' disease — which is the most common cause of thyroid dysfunction and can be present for years before TSH becomes abnormal.",
            tests: [
                LabTest(id: "ta_tpo",  name: "Thyroid Peroxidase Antibodies", abbreviation: "TPO Ab",  unit: "IU/mL",  refRangeLow: 0.0, refRangeHigh: 34.0, femaleRefLow: nil, femaleRefHigh: nil, notes: "Elevated in up to 95% of Hashimoto's cases. Can be positive for years before TSH shifts"),
                LabTest(id: "ta_tgab", name: "Thyroglobulin Antibodies",      abbreviation: "TG Ab",   unit: "IU/mL",  refRangeLow: 0.0, refRangeHigh: 0.9,  femaleRefLow: nil, femaleRefHigh: nil, notes: "Second autoimmune marker for Hashimoto's. Present in ~60–80% of cases"),
                LabTest(id: "ta_rt3",  name: "Reverse T3",                    abbreviation: "rT3",     unit: "ng/dL",  refRangeLow: 9.2, refRangeHigh: 24.1, femaleRefLow: nil, femaleRefHigh: nil, notes: "Inactive T3 metabolite that blocks active T3 receptors. Elevated by chronic stress, caloric restriction, illness. T3:rT3 ratio >20 considered optimal by many clinicians"),
            ],
            orderingNotes: "No special preparation required. Order alongside the basic Thyroid Panel for a comprehensive picture."
        ),
    ]

    // MARK: Convenience accessors

    static var allPanels: [LabPanel] { freePanels + proPanels }

    static func panel(id: String) -> LabPanel? {
        allPanels.first { $0.id == id }
    }

    static func available(isPro: Bool) -> [LabPanel] {
        isPro ? allPanels : freePanels
    }

    static func panels(in category: LabCategory, isPro: Bool) -> [LabPanel] {
        available(isPro: isPro).filter { $0.category == category }
    }
}
