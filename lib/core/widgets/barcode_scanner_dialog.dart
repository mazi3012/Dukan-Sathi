import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_box.dart';
import '../theme/app_colors.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/session.dart';
import '../../models/product.dart';

class BarcodeScannerDialog extends StatefulWidget {
  final Function(Product product) onProductScanned;

  const BarcodeScannerDialog({
    super.key,
    required this.onProductScanned,
  });

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> with SingleTickerProviderStateMixin {
  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _manualController = TextEditingController();
  bool _isSearching = false;
  String? _errorMessage;
  Product? _foundProduct;

  // Pre-configured simulation codes for easy testing
  final List<Map<String, String>> _sampleBarcodes = [
    {'name': 'Parle-G Biscuit', 'code': '8901719101036'},
    {'name': 'Maggi Noodles', 'code': '8901058002315'},
    {'name': 'Dettol Soap 125g', 'code': '8901396386123'},
  ];

  Future<void> _handleScan(String barcode) async {
    if (_isSearching) return;
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundProduct = null;
    });

    final shopId = UserSession().shopId ?? '';
    final product = await _productRepo.getProductByBarcode(shopId, barcode);

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (product != null) {
          _foundProduct = product;
          // Trigger callbacks after a short visual delay for the "success glow"
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              widget.onProductScanned(product);
              Navigator.pop(context);
            }
          });
        } else {
          _errorMessage = "Product not registered with this barcode.";
        }
      });
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassBox(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.scan, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "AI Scanner",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Scanner Viewfinder Mock
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _foundProduct != null 
                          ? Colors.green.withOpacity(0.5) 
                          : (_errorMessage != null ? Colors.red.withOpacity(0.5) : Colors.white12),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Grid Overlay for scanner aesthetic
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GridPainter(color: Colors.white.withOpacity(0.03)),
                        ),
                      ),

                      // Four bracket corners
                      Positioned(top: 16, left: 16, child: _buildCorner(top: true, left: true)),
                      Positioned(top: 16, right: 16, child: _buildCorner(top: true, left: false)),
                      Positioned(bottom: 16, left: 16, child: _buildCorner(top: false, left: true)),
                      Positioned(bottom: 16, right: 16, child: _buildCorner(top: false, left: false)),

                      // Animated Laser line
                      if (_foundProduct == null && !_isSearching)
                        Positioned(
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .slideY(
                           begin: -2.5,
                           end: 2.5,
                           duration: const Duration(seconds: 2),
                           curve: Curves.easeInOut,
                         ),

                      // Overlay state feedback
                      if (_isSearching)
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 12),
                            Text("Indexing product database...", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        )
                      else if (_foundProduct != null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 24),
                            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 12),
                            Text(
                              _foundProduct!.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${_foundProduct!.price.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        )
                      else if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      else
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.barcode, color: Colors.white54, size: 40),
                            SizedBox(height: 8),
                            Text("Align barcode inside frame", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Manual Input
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TextField(
                          controller: _manualController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter barcode manually...",
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_manualController.text.trim().isNotEmpty) {
                          _handleScan(_manualController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 46,
                      ),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Simulator Presets
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Simulated Test Presets:",
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sampleBarcodes.map((preset) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _manualController.text = preset['code']!;
                          _handleScan(preset['code']!);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.barcode, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                preset['name']!,
                                style: const TextStyle(color: Colors.white80, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const step = 20.0;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
