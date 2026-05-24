import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/customer.dart';
import '../../../core/session.dart';
import '../../main/pages/main_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'customer_details_page.dart';
import '../providers/customers_provider.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    Future.microtask(() {
      ref.read(customersProvider.notifier).fetchCustomers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCustomers();
    }
  }

  CustomersState get _state => ref.watch(customersProvider);

  List<Map<String, dynamic>> get _customers => _state.customers;
  bool get _isLoading => _state.isLoading;
  String get _filter => _state.filter;
  String get _searchQuery => _state.searchQuery;
  Map<String, dynamic>? get _selectedCustomer => _state.selectedCustomer;
  
  set _selectedCustomer(Map<String, dynamic>? val) {
    ref.read(customersProvider.notifier).selectCustomer(val);
  }

  set _filter(String val) {
    ref.read(customersProvider.notifier).setFilter(val);
  }

  set _searchQuery(String val) {
    ref.read(customersProvider.notifier).setSearchQuery(val);
  }

  bool get _isLoadingMore => _state.isLoadingMore;
  bool get _hasMore => _state.hasMore;
  double get _outstandingDuesSum => _state.outstandingDuesSum;

  Future<void> _fetchCustomers() async {
    await ref.read(customersProvider.notifier).fetchCustomers();
  }

  Future<void> _loadMoreCustomers() async {
    await ref.read(customersProvider.notifier).loadMoreCustomers();
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
    return _outstandingDuesSum;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: isDesktop ? 20.0 : 80.0), // Above bottom nav on mobile
        child: FloatingActionButton.extended(
          onPressed: () => _showCustomerForm(),
          backgroundColor: AppColors.primary,
          icon: const Icon(Iconsax.user_add, color: Colors.white),
          label: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
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
                  : _buildCustomerList(isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Customer List & Filters
        Expanded(
          flex: 40,
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
                        : _buildCustomerList(isDesktop: true),
              ),
            ],
          ),
        ),
        // Right Column: Split Pane customer profile & details
        Expanded(
          flex: 60,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 20.0, bottom: 20.0),
            child: GlassBox(
              child: _selectedCustomer != null
                  ? CustomerDetailsPage(
                      key: ValueKey(_selectedCustomer!['id']),
                      customer: _selectedCustomer!,
                      isEmbedded: true,
                      onPaymentProcessed: _fetchCustomers,
                    )
                  : const EmptyState(
                      title: "Select a Customer",
                      subtitle: "Choose a customer from the list to view their info, pending dues and transaction history.",
                      icon: Iconsax.user,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Iconsax.menu, size: 24),
                  onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                "Customers",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
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
      onAction: () => _showCustomerForm(),
    );
  }

  Widget _buildListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }

  Widget _buildCustomerList({required bool isDesktop}) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(20, 10, 20, isDesktop ? 20 : 100),
      itemCount: _filteredCustomers.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredCustomers.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }
        final customer = _filteredCustomers[index];
        final name = customer['name'] ?? 'Unknown';
        final phone = customer['phone'] ?? '';
        final balance = (customer['current_balance'] as num?)?.toDouble() ?? 0;
        final hasDues = balance > 0;
        final isSelected = _selectedCustomer != null && _selectedCustomer!['id'] == customer['id'];

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
              color: isSelected 
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.lightPrimary.withOpacity(0.15))
                  : null,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primary
                          : AppColors.lightPrimary,
                      width: 2.0,
                    )
                  : null,
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                onTap: () async {
                  if (isDesktop) {
                    setState(() {
                      _selectedCustomer = customer;
                    });
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetailsPage(customer: customer),
                      ),
                    );
                    _fetchCustomers(); // Refresh balances when returning
                  }
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

  void _showCustomerForm({Map<String, dynamic>? customer}) {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: isEdit ? customer['name'] : '');
    final phoneController = TextEditingController(text: isEdit ? customer['phone'] : '');
    final balanceController = TextEditingController(text: isEdit ? customer['current_balance'].toString() : '0');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? "Edit Customer Details" : "Add New Customer",
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightOnSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text("Customer Name *", style: TextStyle(color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GlassBox(
                child: TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface),
                  decoration: InputDecoration(
                    hintText: "Enter full name",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Phone Number *", style: TextStyle(color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GlassBox(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface),
                  decoration: InputDecoration(
                    hintText: "Enter 10-digit number",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              if (!isEdit) ...[
                const SizedBox(height: 20),
                Text("Initial Balance / Dues (INR)", style: TextStyle(color: isDark ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GlassBox(
                  child: TextField(
                    controller: balanceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightOnSurface),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all required fields"), backgroundColor: AppColors.warning),
                      );
                      return;
                    }
                    Navigator.pop(context);

                    final shopId = UserSession().shopId ?? '';
                    final newCustomer = Customer(
                      id: isEdit ? customer['id'] : const Uuid().v4(),
                      shopId: shopId,
                      name: name,
                      phone: phone,
                      currentBalance: isEdit ? (customer['current_balance'] as num).toDouble() : balance,
                    );

                    if (isEdit) {
                      await ref.read(customersProvider.notifier).updateCustomer(newCustomer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Customer updated successfully!"), backgroundColor: AppColors.success),
                      );
                    } else {
                      await ref.read(customersProvider.notifier).addCustomer(newCustomer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Customer added successfully!"), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? "Update Details" : "Save Customer", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
