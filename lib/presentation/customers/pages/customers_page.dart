import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/database.dart';
import '../../../core/session.dart';
import 'customer_details_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String _filter = 'All'; // All, Dues, Cleared
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    
    final shopId = UserSession().shopId;
    if (shopId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await supabase
          .from('customers')
          .select()
          .eq('shop_id', shopId)
          .order('name');
      
      if (mounted) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Customers] Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    return _customers.where((c) {
      final matchesSearch = c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            c['phone'].toString().contains(_searchQuery);
      if (!matchesSearch) return false;

      final balance = (c['current_balance'] as num?)?.toDouble() ?? 0;
      if (_filter == 'Dues' && balance <= 0) return false;
      if (_filter == 'Cleared' && balance > 0) return false;
      
      return true;
    }).toList();
  }

  double get _totalOutstanding {
    return _customers.fold(0, (sum, c) => sum + ((c['current_balance'] as num?)?.toDouble() ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _isLoading ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonSummaryCard()) : _buildSummaryCard(),
                _buildSearchBar(),
                _buildFilterChips(),
                Expanded(
                  child: _isLoading
                      ? _buildListSkeleton()
                      : _filteredCustomers.isEmpty
                          ? _buildEmptyState()
                          : _buildCustomerList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above bottom nav
        child: FloatingActionButton.extended(
          onPressed: () {
             // Show Add Customer Dialog
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Customer coming soon!')));
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Iconsax.user_add, color: Colors.white),
          label: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Customers",
            style: Theme.of(context).textTheme.displaySmall,
          ),
          IconButton(
            onPressed: _fetchCustomers,
            icon: Icon(Iconsax.refresh, color: Theme.of(context).iconTheme.color),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassBox(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary.withOpacity(0.2) : AppColors.lightPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.wallet_3, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary, size: 28),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Market Dues",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${_totalOutstanding.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.2, curve: Curves.easeOut).fadeIn(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: GlassBox(
        child: TextField(
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: "Search name or phone...",
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            prefixIcon: Icon(Iconsax.search_normal, color: Theme.of(context).iconTheme.color),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: ['All', 'Dues', 'Cleared'].map((filter) {
          final isSelected = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _filter = filter);
              },
              backgroundColor: Theme.of(context).cardColor.withOpacity(0.5),
              selectedColor: Theme.of(context).brightness == Brightness.dark ? AppColors.primary.withOpacity(0.3) : AppColors.lightPrimary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected 
                    ? (Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary) 
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.lightPrimary) : Colors.transparent,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: "No Customers Yet",
      subtitle: "Add your first customer to start tracking dues and sales.",
      icon: Iconsax.user_search,
      actionLabel: "Add Customer",
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Customer coming soon!')));
      },
    );
  }

  Widget _buildListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }

  Widget _buildCustomerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // extra padding for nav/FAB
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        final name = customer['name'] ?? 'Unknown';
        final phone = customer['phone'] ?? '';
        final balance = (customer['current_balance'] as num?)?.toDouble() ?? 0;
        final hasDues = balance > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: Dismissible(
            key: Key(customer['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Iconsax.message, color: Colors.green),
            ),
            confirmDismiss: (direction) async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening WhatsApp for $name...')),
              );
              return false; // Don't actually dismiss the item
            },
            child: GlassBox(
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerDetailsPage(customer: customer),
                    ),
                  );
                  _fetchCustomers(); // Refresh balances when returning
                },
                leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hasDues 
                      ? AppColors.error.withOpacity(0.1) 
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasDues ? Iconsax.warning_2 : Iconsax.verify,
                  color: hasDues ? AppColors.error : AppColors.success,
                ),
              ),
              title: Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                phone,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasDues ? "Due: ₹${balance.toStringAsFixed(0)}" : "Cleared",
                    style: TextStyle(
                      color: hasDues ? AppColors.error : AppColors.success, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                    ),
                  ),
                  if (hasDues)
                    Text(
                      "Swipe to settle",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ).animate().slideX(begin: 0.1, delay: (index * 50).ms).fadeIn();
    },
    );
  }
}
