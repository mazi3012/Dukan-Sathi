/// GST Tax Slab Database for all Indian states and UTs
/// Reference: GST Council official rates as of 2026
library;

class StateTaxSlabs {
  static const Map<String, String> stateNames = {
    // States (28)
    'AP': 'Andhra Pradesh',
    'AR': 'Arunachal Pradesh',
    'AS': 'Assam',
    'BR': 'Bihar',
    'CG': 'Chhattisgarh',
    'GA': 'Goa',
    'GJ': 'Gujarat',
    'HR': 'Haryana',
    'HP': 'Himachal Pradesh',
    'JK': 'Jammu & Kashmir',
    'JH': 'Jharkhand',
    'KA': 'Karnataka',
    'KL': 'Kerala',
    'MP': 'Madhya Pradesh',
    'MH': 'Maharashtra',
    'MN': 'Manipur',
    'ML': 'Meghalaya',
    'MZ': 'Mizoram',
    'OD': 'Odisha',
    'PB': 'Punjab',
    'RJ': 'Rajasthan',
    'SK': 'Sikkim',
    'TN': 'Tamil Nadu',
    'TS': 'Telangana',
    'TR': 'Tripura',
    'UP': 'Uttar Pradesh',
    'UK': 'Uttarakhand',
    'WB': 'West Bengal',
    // Union Territories (8)
    'AN': 'Andaman & Nicobar',
    'CH': 'Chandigarh',
    'DL': 'Delhi',
    'DD': 'Dadra & Nagar Haveli',
    'DH': 'Daman & Diu',
    'JL': 'Jammu & Ladakh',
    'LA': 'Ladakh',
    'LD': 'Lakshadweep',
    'PY': 'Puducherry',
  };

  /// GST Slabs for standard retail goods (18% slab default for Dukan Sathi)
  /// Key: State code, Value: Slab percentage
  static const Map<String, int> defaultRates = {
    // Most common: 18% slab for retail
    'AP': 18,
    'AR': 18,
    'AS': 18,
    'BR': 18,
    'CG': 18,
    'GA': 18,
    'GJ': 18,
    'HR': 18,
    'HP': 18,
    'JK': 18,
    'JH': 18,
    'KA': 18,
    'KL': 18,
    'MP': 18,
    'MH': 18,
    'MN': 18,
    'ML': 18,
    'MZ': 18,
    'OD': 18,
    'PB': 18,
    'RJ': 18,
    'SK': 18,
    'TN': 18,
    'TS': 18,
    'TR': 18,
    'UP': 18,
    'UK': 18,
    'WB': 18,
    // Union Territories
    'AN': 18,
    'CH': 18,
    'DL': 18,
    'DD': 18,
    'DH': 18,
    'JL': 18,
    'LA': 18,
    'LD': 18,
    'PY': 18,
  };

  /// High-value items (28% slab) - Luxury goods, tobacco products, etc.
  static const List<String> slab28Items = [
    'Tobacco',
    'Cigarettes',
    'Cigars',
    'Luxury cosmetics',
    'Premium beverages',
    'High-end electronics',
  ];

  /// Standard items (18% slab) - Most retail goods
  static const List<String> slab18Items = [
    'Retail goods',
    'Clothing',
    'Electronics',
    'Cosmetics',
    'Toys',
    'Books',
    'Medicines',
    'Packaged food',
    'Beverages',
  ];

  /// Mid-range items (12% slab)
  static const List<String> slab12Items = [
    'Textiles',
    'Fabrics',
    'Footwear',
    'Processed food',
  ];

  /// Essential items (5% slab)
  static const List<String> slab5Items = [
    'Pre-packaged food',
    'Cereals',
    'Pulses',
    'Flour',
    'Bread',
    'Milk',
  ];

  /// Zero-rated / Exempt items
  static const List<String> exemptItems = [
    'Fresh fruits',
    'Fresh vegetables',
    'Eggs',
    'Honey',
  ];

  /// Get state name from code
  static String getStateName(String stateCode) {
    return stateNames[stateCode] ?? 'Unknown State';
  }

  /// Get default GST rate for a state
  static int getDefaultRate(String stateCode) {
    return defaultRates[stateCode] ?? 18; // Default to 18%
  }

  /// Check if state code is valid
  static bool isValidState(String stateCode) {
    return stateNames.containsKey(stateCode);
  }

  /// Get CGST rate (half of total for registered)
  static double getCGSTRate(int totalSlab) {
    return totalSlab / 2;
  }

  /// Get SGST rate (half of total for registered intra-state)
  static double getSGSTRate(int totalSlab) {
    return totalSlab / 2;
  }

  /// Get IGST rate (full slab for inter-state)
  static double getIGSTRate(int totalSlab) {
    return totalSlab.toDouble();
  }

  /// Determine slab for a product (can be extended for HSN code lookup)
  static int getProductSlab(String productName) {
    final lower = productName.toLowerCase();

    if (slab28Items.any((item) => lower.contains(item.toLowerCase()))) {
      return 28;
    } else if (slab12Items.any((item) => lower.contains(item.toLowerCase()))) {
      return 12;
    } else if (slab5Items.any((item) => lower.contains(item.toLowerCase()))) {
      return 5;
    } else if (
        exemptItems.any((item) => lower.contains(item.toLowerCase()))) {
      return 0;
    }
    return 18; // Default for retail
  }

  /// All valid state codes
  static List<String> getAllStatesCodes() {
    return stateNames.keys.toList();
  }
}
