import Foundation

// MARK: - Catalog types

enum AppTier: String, Codable {
    case free
    case pro
}

/// A static entry in the built-in regimen catalog.
/// These are not SwiftData models — they are compiled into the app and never change at runtime.
/// When a user adds a catalog item to their regimen, a RegimenItem is created with catalogId = id.
struct CatalogItem: Identifiable {
    let id: String                          // stable slug, e.g. "vitamin-d3"
    let name: String
    let category: RegimenCategory
    let tier: AppTier
    let description: String                 // 1-line benefit summary shown in catalog
    let defaultAmountValue: Double
    let defaultUnit: String
    let defaultTimeOfDay: TimeOfDay
    let defaultScheduleType: ScheduleType
    let defaultCycleDaysOn: Int?            // for .cyclic items
    let defaultCycleDaysOff: Int?
    let defaultLongCycleActiveWeeks: Int?   // for items with long rest periods
    let defaultLongCycleRestWeeks: Int?
    let isInjectable: Bool
    let prescriptionRequired: Bool          // informational flag, not a hard gate
    let researchNotes: String               // optional dosing/timing context
}

// MARK: - Catalog data

struct RegimenCatalog {

    // MARK: Free tier — 15 items

    static let freeItems: [CatalogItem] = [

        CatalogItem(
            id: "vitamin-d3",
            name: "Vitamin D3",
            category: .supplement,
            tier: .free,
            description: "Immune function, bone health, mood regulation",
            defaultAmountValue: 5000, defaultUnit: "IU",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Take with K2 and a fat-containing meal for best absorption."
        ),

        CatalogItem(
            id: "omega-3",
            name: "Omega-3 (Fish Oil)",
            category: .supplement,
            tier: .free,
            description: "Cardiovascular health, cognitive function, inflammation",
            defaultAmountValue: 2000, defaultUnit: "mg EPA/DHA",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Minimise fishy aftertaste by taking with meals or refrigerating capsules."
        ),

        CatalogItem(
            id: "creatine",
            name: "Creatine Monohydrate",
            category: .supplement,
            tier: .free,
            description: "Strength, power output, cognitive reserve",
            defaultAmountValue: 5, defaultUnit: "g",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "No loading phase required. Timing is not critical — consistency matters more."
        ),

        CatalogItem(
            id: "magnesium-glycinate",
            name: "Magnesium Glycinate",
            category: .supplement,
            tier: .free,
            description: "Sleep quality, muscle recovery, stress regulation",
            defaultAmountValue: 400, defaultUnit: "mg",
            defaultTimeOfDay: .beforeBed, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Glycinate form is highly bioavailable and gentler on digestion than oxide."
        ),

        CatalogItem(
            id: "protein-whey",
            name: "Protein (Whey)",
            category: .protein,
            tier: .free,
            description: "Muscle protein synthesis, satiety, recovery",
            defaultAmountValue: 30, defaultUnit: "g",
            defaultTimeOfDay: .preWorkout, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Post-workout window is real but not urgent — total daily protein intake matters most."
        ),

        CatalogItem(
            id: "zinc",
            name: "Zinc",
            category: .supplement,
            tier: .free,
            description: "Testosterone support, immune function, wound healing",
            defaultAmountValue: 30, defaultUnit: "mg",
            defaultTimeOfDay: .evening, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Take away from calcium supplements. High doses long-term can deplete copper."
        ),

        CatalogItem(
            id: "vitamin-b12",
            name: "Vitamin B12",
            category: .supplement,
            tier: .free,
            description: "Energy metabolism, nerve function, red blood cell production",
            defaultAmountValue: 1000, defaultUnit: "mcg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Methylcobalamin form preferred. Sublingual or injectable is better for those with absorption issues."
        ),

        CatalogItem(
            id: "ashwagandha",
            name: "Ashwagandha (KSM-66)",
            category: .supplement,
            tier: .free,
            description: "Stress and cortisol reduction, sleep, testosterone support",
            defaultAmountValue: 600, defaultUnit: "mg",
            defaultTimeOfDay: .beforeBed, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "KSM-66 and Sensoril are the most studied extracts. Some cycle 8 weeks on / 4 weeks off."
        ),

        CatalogItem(
            id: "vitamin-c",
            name: "Vitamin C",
            category: .supplement,
            tier: .free,
            description: "Antioxidant, immune support, collagen synthesis",
            defaultAmountValue: 1000, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Divided doses (500mg 2x/day) improve absorption above 200mg."
        ),

        CatalogItem(
            id: "vitamin-k2",
            name: "Vitamin K2 (MK-7)",
            category: .supplement,
            tier: .free,
            description: "Directs calcium to bones not arteries; pairs with D3",
            defaultAmountValue: 100, defaultUnit: "mcg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "MK-7 has a longer half-life than MK-4. Take with D3 and a fat-containing meal."
        ),

        CatalogItem(
            id: "coq10",
            name: "CoQ10 (Ubiquinol)",
            category: .supplement,
            tier: .free,
            description: "Mitochondrial energy production, antioxidant, heart health",
            defaultAmountValue: 200, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Ubiquinol is the active, reduced form — better absorbed than ubiquinone."
        ),

        CatalogItem(
            id: "nac",
            name: "NAC (N-Acetyl Cysteine)",
            category: .supplement,
            tier: .free,
            description: "Glutathione precursor, antioxidant, liver support",
            defaultAmountValue: 600, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Take on an empty stomach for best absorption. Some cycle to avoid tolerance."
        ),

        CatalogItem(
            id: "berberine",
            name: "Berberine",
            category: .supplement,
            tier: .free,
            description: "Blood glucose regulation, metabolic health, AMPK activation",
            defaultAmountValue: 500, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Often taken 2-3x/day with meals. Some cycle 8 weeks on / 4 weeks off."
        ),

        CatalogItem(
            id: "melatonin",
            name: "Melatonin",
            category: .supplement,
            tier: .free,
            description: "Sleep onset, circadian rhythm regulation",
            defaultAmountValue: 0.5, defaultUnit: "mg",
            defaultTimeOfDay: .beforeBed, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Lower doses (0.5–1mg) are often more effective than the typical 5–10mg products."
        ),

        CatalogItem(
            id: "probiotics",
            name: "Probiotics",
            category: .supplement,
            tier: .free,
            description: "Gut microbiome diversity, immune function, digestion",
            defaultAmountValue: 50, defaultUnit: "billion CFU",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Multi-strain products are generally preferred. Take away from antibiotics."
        ),
    ]

    // MARK: Pro tier

    static let proItems: [CatalogItem] = [

        // Peptides
        CatalogItem(
            id: "bpc-157",
            name: "BPC-157",
            category: .peptide,
            tier: .pro,
            description: "Healing, gut health, joint and tendon repair",
            defaultAmountValue: 250, defaultUnit: "mcg",
            defaultTimeOfDay: .morning, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 5, defaultCycleDaysOff: 2,
            defaultLongCycleActiveWeeks: 8, defaultLongCycleRestWeeks: 4,
            isInjectable: true, prescriptionRequired: false,
            researchNotes: "Subcutaneous injection near the site of injury is common. Oral form also studied for gut issues."
        ),

        CatalogItem(
            id: "tb-500",
            name: "TB-500",
            category: .peptide,
            tier: .pro,
            description: "Tissue repair, flexibility, systemic recovery",
            defaultAmountValue: 5, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 1, defaultCycleDaysOff: 6,
            defaultLongCycleActiveWeeks: 6, defaultLongCycleRestWeeks: 4,
            isInjectable: true, prescriptionRequired: false,
            researchNotes: "Typically dosed 2–5mg twice weekly for loading, then once weekly for maintenance."
        ),

        CatalogItem(
            id: "ipamorelin-cjc1295",
            name: "Ipamorelin / CJC-1295",
            category: .peptide,
            tier: .pro,
            description: "GH secretion support, recovery, body composition",
            defaultAmountValue: 300, defaultUnit: "mcg",
            defaultTimeOfDay: .beforeBed, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 5, defaultCycleDaysOff: 2,
            defaultLongCycleActiveWeeks: 12, defaultLongCycleRestWeeks: 4,
            isInjectable: true, prescriptionRequired: false,
            researchNotes: "Best administered before sleep to align with natural GH pulses. Avoid carbs 2 hours before."
        ),

        CatalogItem(
            id: "ghk-cu",
            name: "GHK-Cu (Copper Peptide)",
            category: .peptide,
            tier: .pro,
            description: "Wound healing, anti-aging, hair growth, collagen synthesis",
            defaultAmountValue: 2, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 5, defaultCycleDaysOff: 2,
            defaultLongCycleActiveWeeks: 8, defaultLongCycleRestWeeks: 4,
            isInjectable: true, prescriptionRequired: false,
            researchNotes: "Topical and injectable forms both studied. Cycle to avoid receptor desensitisation."
        ),

        CatalogItem(
            id: "selank",
            name: "Selank",
            category: .peptide,
            tier: .pro,
            description: "Anxiolytic, cognitive enhancement, immune modulation",
            defaultAmountValue: 250, defaultUnit: "mcg",
            defaultTimeOfDay: .morning, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 5, defaultCycleDaysOff: 2,
            defaultLongCycleActiveWeeks: 4, defaultLongCycleRestWeeks: 2,
            isInjectable: true, prescriptionRequired: false,
            researchNotes: "Intranasal administration is common and effective. Often cycled to preserve effect."
        ),

        CatalogItem(
            id: "semax",
            name: "Semax",
            category: .peptide,
            tier: .pro,
            description: "Nootropic, BDNF upregulation, focus and neuroprotection",
            defaultAmountValue: 300, defaultUnit: "mcg",
            defaultTimeOfDay: .morning, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 5, defaultCycleDaysOff: 2,
            defaultLongCycleActiveWeeks: 4, defaultLongCycleRestWeeks: 2,
            isInjectable: true, prescriptionRequired: false,
            researchNotes: "Intranasal. Stack with Selank for balanced stimulation and anxiolysis."
        ),

        CatalogItem(
            id: "epithalon",
            name: "Epithalon",
            category: .peptide,
            tier: .pro,
            description: "Telomere elongation, sleep regulation, longevity",
            defaultAmountValue: 10, defaultUnit: "mg",
            defaultTimeOfDay: .beforeBed, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: 3, defaultLongCycleRestWeeks: 24,
            isInjectable: true, prescriptionRequired: false,
            researchNotes: "Typically run as a 10-day course once or twice per year."
        ),

        // Nootropics
        CatalogItem(
            id: "lions-mane",
            name: "Lion's Mane",
            category: .nootropic,
            tier: .pro,
            description: "NGF support, cognitive function, neuroprotection",
            defaultAmountValue: 1000, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Full-spectrum fruiting body extracts are preferred over mycelium-only products."
        ),

        CatalogItem(
            id: "alpha-gpc",
            name: "Alpha-GPC",
            category: .nootropic,
            tier: .pro,
            description: "Choline source, acetylcholine support, focus and cognition",
            defaultAmountValue: 300, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Best absorbed on an empty stomach. Avoid too late in the day if it affects sleep."
        ),

        CatalogItem(
            id: "bacopa",
            name: "Bacopa Monnieri",
            category: .nootropic,
            tier: .pro,
            description: "Memory consolidation, anxiety reduction, adaptogen",
            defaultAmountValue: 300, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Effects on memory accumulate over 4–8 weeks. Take with a fat-containing meal."
        ),

        CatalogItem(
            id: "phosphatidylserine",
            name: "Phosphatidylserine",
            category: .nootropic,
            tier: .pro,
            description: "Cortisol blunting, memory, cognitive aging support",
            defaultAmountValue: 200, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Particularly useful for high-stress periods or heavy training blocks."
        ),

        // Longevity / metabolic
        CatalogItem(
            id: "nmn",
            name: "NMN",
            category: .supplement,
            tier: .pro,
            description: "NAD+ precursor, energy metabolism, cellular repair",
            defaultAmountValue: 500, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Take in the morning — NAD+ synthesis follows circadian patterns. Sublingual NMN has better bioavailability."
        ),

        CatalogItem(
            id: "resveratrol",
            name: "Resveratrol",
            category: .supplement,
            tier: .pro,
            description: "Sirtuin activation, cardiovascular protection, longevity",
            defaultAmountValue: 500, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Often taken alongside NMN. Trans-resveratrol is the active form."
        ),

        CatalogItem(
            id: "spermidine",
            name: "Spermidine",
            category: .supplement,
            tier: .pro,
            description: "Autophagy induction, cardiovascular health, longevity",
            defaultAmountValue: 10, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Naturally found in wheat germ, soy, and aged cheeses. Fasting potentiates the autophagy effect."
        ),

        // Performance
        CatalogItem(
            id: "l-carnitine",
            name: "L-Carnitine",
            category: .supplement,
            tier: .pro,
            description: "Fat metabolism, recovery, androgen receptor density",
            defaultAmountValue: 2000, defaultUnit: "mg",
            defaultTimeOfDay: .preWorkout, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Absorption is enhanced when taken with carbohydrates (insulin-mediated transport into muscle)."
        ),

        CatalogItem(
            id: "citrulline-malate",
            name: "Citrulline Malate",
            category: .supplement,
            tier: .pro,
            description: "Nitric oxide production, pump, endurance, recovery",
            defaultAmountValue: 6000, defaultUnit: "mg",
            defaultTimeOfDay: .preWorkout, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "6–8g 60 minutes before training is well-supported. More effective than arginine."
        ),

        // Hormonal support (injectables)
        CatalogItem(
            id: "testosterone-cypionate",
            name: "Testosterone Cypionate",
            category: .injectable,
            tier: .pro,
            description: "TRT / hormone optimisation",
            defaultAmountValue: 100, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 1, defaultCycleDaysOff: 6,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: true, prescriptionRequired: true,
            researchNotes: "Subcutaneous or intramuscular. Rotate injection sites. Prescription required."
        ),

        CatalogItem(
            id: "dhea",
            name: "DHEA",
            category: .supplement,
            tier: .pro,
            description: "Adrenal hormone precursor, energy, libido, anti-aging",
            defaultAmountValue: 25, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Start low (10–25mg) and test DHEA-S levels before increasing. Can convert to oestrogen."
        ),

        CatalogItem(
            id: "pregnenolone",
            name: "Pregnenolone",
            category: .supplement,
            tier: .pro,
            description: "Master hormone precursor, cognitive function, mood",
            defaultAmountValue: 50, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: false,
            researchNotes: "Upstream of DHEA and progesterone. Test levels before and after to guide dosing."
        ),

        // Prescription-flagged (visible with informational flag)
        CatalogItem(
            id: "metformin",
            name: "Metformin",
            category: .supplement,
            tier: .pro,
            description: "AMPK activation, glucose regulation, longevity research",
            defaultAmountValue: 500, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .daily,
            defaultCycleDaysOn: nil, defaultCycleDaysOff: nil,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: false, prescriptionRequired: true,
            researchNotes: "Prescription required. Some longevity researchers use low-dose. May blunt some exercise adaptations."
        ),

        CatalogItem(
            id: "semaglutide",
            name: "Semaglutide",
            category: .injectable,
            tier: .pro,
            description: "GLP-1 agonist, appetite regulation, metabolic health",
            defaultAmountValue: 0.25, defaultUnit: "mg",
            defaultTimeOfDay: .morning, defaultScheduleType: .cyclic,
            defaultCycleDaysOn: 1, defaultCycleDaysOff: 6,
            defaultLongCycleActiveWeeks: nil, defaultLongCycleRestWeeks: nil,
            isInjectable: true, prescriptionRequired: true,
            researchNotes: "Prescription required. Subcutaneous. Titrate slowly to minimise GI side effects."
        ),
    ]

    // MARK: Lookup helpers

    static var allItems: [CatalogItem] { freeItems + proItems }

    static func item(id: String) -> CatalogItem? {
        allItems.first { $0.id == id }
    }

    /// Items the user can add based on their tier.
    static func available(isPro: Bool) -> [CatalogItem] {
        isPro ? allItems : freeItems
    }

    /// Category sections for the catalog UI.
    static var proCategories: [RegimenCategory] {
        [.peptide, .nootropic, .injectable, .supplement]
    }
}

// MARK: - RegimenItem construction

extension CatalogItem {

    /// Builds a `RegimenItem` (with its single default `DoseSlot`) from this
    /// catalog entry's defaults. Caller is responsible for inserting both the
    /// item and its dose slots into the `ModelContext`.
    func makeRegimenItem(startDate: Date = Date()) -> RegimenItem {
        let item = RegimenItem(name: name, category: category, catalogId: id)
        item.startDate = startDate
        item.scheduleType = defaultScheduleType
        item.isInjectable = isInjectable

        if let cycleDaysOn = defaultCycleDaysOn, let cycleDaysOff = defaultCycleDaysOff {
            item.cycleDaysOn = cycleDaysOn
            item.cycleDaysOff = cycleDaysOff
        }
        if let activeWeeks = defaultLongCycleActiveWeeks, let restWeeks = defaultLongCycleRestWeeks {
            item.hasLongCycle = true
            item.longCycleActiveWeeks = activeWeeks
            item.longCycleRestWeeks = restWeeks
            item.longCycleStartDate = startDate
        }

        let slot = DoseSlot(timeOfDay: defaultTimeOfDay, amount: defaultAmountValue, unit: defaultUnit)
        slot.regimenItem = item
        item.doseSlots = [slot]

        return item
    }
}
