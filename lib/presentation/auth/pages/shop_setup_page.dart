import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/session.dart';

class ShopSetupPage extends StatefulWidget {
  const ShopSetupPage({super.key});

  @override
  State<ShopSetupPage> createState() => _ShopSetupPageState();
}

class _ShopSetupPageState extends State<ShopSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _gstController = TextEditingController();
  final _upiController = TextEditingController();
  String _selectedState = 'West Bengal';
  String _gstMode = 'UNREGISTERED';
  bool _isLoading = false;

  final Map<String, String> _stateCodes = {
    'Andhra Pradesh': 'AP', 'Arunachal Pradesh': 'AR', 'Assam': 'AS', 'Bihar': 'BR',
    'Chhattisgarh': 'CG', 'Goa': 'GA', 'Gujarat': 'GJ', 'Haryana': 'HR',
    'Himachal Pradesh': 'HP', 'Jammu & Kashmir': 'JK', 'Jharkhand': 'JH',
    'Karnataka': 'KA', 'Kerala': 'KL', 'Madhya Pradesh': 'MP', 'Maharashtra': 'MH',
    'Manipur': 'MN', 'Meghalaya': 'ML', 'Mizoram': 'MZ', 'Nagaland': 'NL',
    'Odisha': 'OD', 'Punjab': 'PB', 'Rajasthan': 'RJ', 'Sikkim': 'SK',
    'Tamil Nadu': 'TN', 'Telangana': 'TS', 'Tripura': 'TR', 'Uttar Pradesh': 'UP',
    'Uttarakhand': 'UK', 'West Bengal': 'WB', 'Andaman & Nicobar': 'AN',
    'Chandigarh': 'CH', 'Delhi': 'DL', 'Dadra & Nagar Haveli': 'DH',
    'Daman & Diu': 'DD', 'Ladakh': 'LA', 'Lakshadweep': 'LD', 'Puducherry': 'PY'
  };

  late List<String> _indianStates;

  @override
  void initState() {
    super.initState();
    _indianStates = _stateCodes.keys.toList()..sort();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final stateCode = _stateCodes[_selectedState] ?? 'WB';

    final result = await UserSession().createShop(
      name: _nameController.text,
      state: stateCode,
      businessType: _businessTypeController.text,
      gstNumber: _gstController.text.isNotEmpty ? _gstController.text : null,
      gstMode: _gstMode,
      upiId: _upiController.text.isNotEmpty ? _upiController.text : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        // AuthGate will rebuild and show MainLayout
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Setup failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.shop, size: 48, color: Theme.of(context).primaryColor)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(),
                  const SizedBox(height: 24),
                  Text(
                    "Setup Your Shop",
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  const SizedBox(height: 8),
                  Text(
                    "Just a few details to get your digital dukan ready.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 48),
                  
                  _buildLabel("Shop Name"),
                  _buildTextField(
                    controller: _nameController,
                    hint: "e.g. Mazi Electronics",
                    icon: Iconsax.shop,
                    validator: (v) => v!.isEmpty ? "Enter shop name" : null,
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 24),
                  
                  _buildLabel("Business Type"),
                  _buildTextField(
                    controller: _businessTypeController,
                    hint: "e.g. Retail, Wholesale, Grocery",
                    icon: Iconsax.category,
                    validator: (v) => v!.isEmpty ? "Enter business type" : null,
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 24),
                  
                  _buildLabel("State"),
                  _buildDropdown().animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 24),
                  
                  _buildLabel("GST Registration"),
                  _buildGstModeSelector().animate().fadeIn(delay: 650.ms),
                  
                  if (_gstMode != 'UNREGISTERED') ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _gstController,
                      hint: "Enter 15-digit GSTIN",
                      icon: Iconsax.document_text,
                      validator: (v) => v!.isEmpty ? "Enter GST number" : null,
                    ).animate().fadeIn(),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  _buildLabel("UPI ID for Payments (Optional)"),
                  _buildTextField(
                    controller: _upiController,
                    hint: "e.g. shopname@okicici",
                    icon: Iconsax.wallet_check,
                  ).animate().fadeIn(delay: 700.ms),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Create Shop",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).scale(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return GlassBox(
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return GlassBox(
      child: DropdownButtonFormField<String>(
        value: _selectedState,
        dropdownColor: Theme.of(context).cardColor,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        decoration: const InputDecoration(
          prefixIcon: Icon(Iconsax.location, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 0),
        ),
        items: _indianStates.map((String state) {
          return DropdownMenuItem<String>(
            value: state,
            child: Text(state),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() => _selectedState = newValue);
          }
        },
      ),
    );
  }

  Widget _buildGstModeSelector() {
    return Row(
      children: ['UNREGISTERED', 'REGISTERED', 'COMPOSITE'].map((mode) {
        final isSelected = _gstMode == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gstMode = mode),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.2) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.lightGlass),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppColors.lightGlassBorder),
                ),
              ),
              child: Center(
                child: Text(
                  mode.split('_')[0],
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
