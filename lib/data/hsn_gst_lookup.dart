/// HSN/SAC Code → GST Rate Lookup Table
/// Reference: CBIC GST Council official rates (common items for retail/kirana shops)
///
/// Valid Indian GST slabs: 0, 0.1, 0.25, 1.5, 3, 5, 6, 12, 18, 28

class HsnGstLookup {
  /// Valid GST rate slabs in India
  static const List<double> validGstSlabs = [0, 0.1, 0.25, 1.5, 3, 5, 6, 12, 18, 28];

  /// Common HSN codes → GST rate mapping (4-digit and 8-digit)
  /// Covers essentials, FMCG, grocery, electronics, clothing, services
  static const Map<String, double> hsnToRate = {
    // ─── 0% (Exempt / Nil rated) ─────────────────────────────────────────
    '0713': 0,      // Dried leguminous vegetables (unbranded)
    '0201': 0,      // Meat of bovine animals, fresh
    '0301': 0,      // Live fish
    '0401': 0,      // Milk, not concentrated (fresh milk)
    '0407': 0,      // Birds' eggs, in shell, fresh
    '0701': 0,      // Potatoes, fresh
    '0702': 0,      // Tomatoes, fresh
    '0703': 0,      // Onions, fresh
    '0706': 0,      // Carrots, turnips, fresh
    '0707': 0,      // Cucumbers, fresh
    '0709': 0,      // Other vegetables, fresh
    '0713': 0,      // Dried legumes
    '0803': 0,      // Bananas, fresh
    '0805': 0,      // Citrus fruit, fresh
    '0806': 0,      // Grapes, fresh
    '0807': 0,      // Melons, watermelons, fresh
    '0808': 0,      // Apples, fresh
    '0810': 0,      // Other fruit, fresh
    '1001': 0,      // Wheat and meslin (unbranded)
    '1006': 0,      // Rice (unbranded, not put up in unit container)
    '1007': 0,      // Grain sorghum
    '0409': 0,      // Natural honey
    '0801': 0,      // Coconuts, fresh
    '2201': 0,      // Water (not aerated, not sweetened)

    // ─── 5% GST ──────────────────────────────────────────────────────────
    '0402': 5,      // Milk, concentrated or sweetened (branded)
    '0901': 5,      // Coffee (not roasted)
    '0902': 5,      // Tea
    '1101': 5,      // Wheat or meslin flour (branded)
    '1006': 5,      // Rice (branded, put up in unit container) — NOTE: branded override
    '1905': 5,      // Bread, pastry, cakes
    '1702': 5,      // Sugar (other than cane sugar)
    '1701': 5,      // Cane or beet sugar
    '1704': 5,      // Sugar confectionery
    '2106': 5,      // Food preparations NES
    '1902': 5,      // Pasta
    '0910': 5,      // Ginger, saffron, turmeric, spices
    '0904': 5,      // Pepper
    '1104': 5,      // Cereal grains (rolled or flaked)
    '1507': 5,      // Soybean oil
    '1508': 5,      // Groundnut oil
    '1509': 5,      // Olive oil
    '1510': 5,      // Other olive oil
    '1511': 5,      // Palm oil
    '1512': 5,      // Sunflower oil
    '1515': 5,      // Mustard oil
    '3401': 5,      // Soap (for household use)
    '4802': 5,      // Newsprint
    '9988': 5,      // SAC: Transport services

    // ─── 12% GST ─────────────────────────────────────────────────────────
    '0802': 12,     // Nuts, dried (almonds, cashew, etc.)
    '1604': 12,     // Prepared or preserved fish
    '1806': 12,     // Chocolate and cocoa preparations
    '1901': 12,     // Malt extract, food preparations
    '2009': 12,     // Fruit juices
    '2202': 12,     // Flavoured/sweetened water, soft drinks base
    '3304': 12,     // Beauty/makeup preparations
    '3307': 12,     // Deodorants, perfumes
    '3924': 12,     // Household articles of plastics
    '4818': 12,     // Toilet/tissue paper
    '6101': 12,     // Men's coats, jackets (knitted) — value > ₹1000
    '6102': 12,     // Women's coats, jackets (knitted) — value > ₹1000
    '6103': 12,     // Men's suits, trousers (knitted)
    '6104': 12,     // Women's suits, trousers (knitted)
    '6109': 12,     // T-shirts, singlets (knitted) — value > ₹1000
    '6203': 12,     // Men's suits, trousers (not knitted)
    '6204': 12,     // Women's suits, trousers (not knitted)
    '6205': 12,     // Men's shirts (not knitted) — value > ₹1000
    '6206': 12,     // Women's shirts (not knitted) — value > ₹1000
    '6403': 12,     // Footwear (value > ₹1000)
    '6404': 12,     // Sports footwear
    '9963': 12,     // SAC: Accommodation services (hotels ₹1001-₹7500)
    '9972': 12,     // SAC: Real estate services
    '9992': 12,     // SAC: Education services

    // ─── 18% GST ─────────────────────────────────────────────────────────
    '0403': 18,     // Yoghurt, buttermilk (flavoured)
    '0404': 18,     // Whey
    '2103': 18,     // Sauces, ketchup, mustard
    '2104': 18,     // Soups, broths
    '2105': 18,     // Ice cream
    '2106': 18,     // Food preparations NES (branded)
    '3304': 18,     // Cosmetics, beauty preparations
    '3305': 18,     // Hair preparations (shampoo, conditioner)
    '3306': 18,     // Oral hygiene (toothpaste)
    '3401': 18,     // Soap (beauty, premium)
    '3402': 18,     // Detergents, cleaning agents
    '3808': 18,     // Insecticides, disinfectants
    '3923': 18,     // Plastic articles for packing
    '4202': 18,     // Trunks, suitcases, handbags
    '4819': 18,     // Cartons, boxes
    '4820': 18,     // Notebooks, registers
    '4823': 18,     // Paper articles
    '6910': 18,     // Ceramic sinks, basins
    '7013': 18,     // Glassware
    '7310': 18,     // Tanks, casks (iron/steel)
    '7615': 18,     // Aluminium articles (utensils)
    '8414': 18,     // Air pumps, fans
    '8415': 18,     // Air conditioning machines
    '8418': 18,     // Refrigerators, freezers
    '8422': 18,     // Dish washing machines
    '8443': 18,     // Printers, scanners
    '8450': 18,     // Washing machines
    '8471': 18,     // Computers, laptops
    '8504': 18,     // Electric transformers, chargers
    '8507': 18,     // Electric batteries
    '8508': 18,     // Vacuum cleaners
    '8509': 18,     // Electro-mechanical appliances
    '8516': 18,     // Electric heaters, hair dryers, irons
    '8517': 18,     // Telephones, smartphones
    '8518': 18,     // Microphones, speakers
    '8521': 18,     // Video recording apparatus
    '8523': 18,     // Discs, tapes, media
    '8525': 18,     // Cameras (TV, digital)
    '8527': 18,     // Radio broadcast receivers
    '8528': 18,     // Monitors, projectors, TVs
    '8544': 18,     // Insulated wire, cables
    '9403': 18,     // Other furniture
    '9504': 18,     // Video games, entertainment
    '9971': 18,     // SAC: Financial services
    '9973': 18,     // SAC: Leasing services
    '9982': 18,     // SAC: Legal services
    '9983': 18,     // SAC: Accounting, auditing
    '9984': 18,     // SAC: Telecommunications
    '9985': 18,     // SAC: Support services
    '9986': 18,     // SAC: Support services to agriculture
    '9987': 18,     // SAC: Maintenance and repair
    '9991': 18,     // SAC: Government services
    '9997': 18,     // SAC: Other services NES

    // ─── 28% GST ─────────────────────────────────────────────────────────
    '2101': 28,     // Extracts of coffee/tea (certain preparations)
    '2402': 28,     // Cigars, cigarettes, tobacco
    '2403': 28,     // Other manufactured tobacco
    '3303': 28,     // Perfumes, eau de toilette (premium)
    '7101': 28,     // Pearls
    '7102': 28,     // Diamonds
    '8703': 28,     // Motor cars (passenger vehicles)
    '8704': 28,     // Motor vehicles for goods transport
    '8711': 28,     // Motorcycles
    '8903': 28,     // Yachts, boats (pleasure)
    '9302': 28,     // Revolvers, pistols
    '9504': 28,     // Gambling/betting equipment
  };

  /// Look up GST rate by HSN/SAC code.
  /// Tries exact match first, then 4-digit prefix match.
  /// Returns null if no match found.
  static double? lookupRate(String? hsnCode) {
    if (hsnCode == null || hsnCode.trim().isEmpty) return null;

    final code = hsnCode.trim();

    // Exact match
    if (hsnToRate.containsKey(code)) {
      return hsnToRate[code];
    }

    // 4-digit prefix match (most HSN codes are 4 or 8 digits)
    if (code.length > 4) {
      final prefix = code.substring(0, 4);
      if (hsnToRate.containsKey(prefix)) {
        return hsnToRate[prefix];
      }
    }

    return null;
  }

  /// Validate if a GST rate is a valid Indian slab
  static bool isValidRate(double rate) {
    return validGstSlabs.contains(rate);
  }

  /// Get the nearest valid GST slab for a given rate
  static double nearestValidSlab(double rate) {
    if (validGstSlabs.contains(rate)) return rate;
    double closest = validGstSlabs.first;
    double minDiff = (rate - closest).abs();
    for (final slab in validGstSlabs) {
      final diff = (rate - slab).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = slab;
      }
    }
    return closest;
  }
}
