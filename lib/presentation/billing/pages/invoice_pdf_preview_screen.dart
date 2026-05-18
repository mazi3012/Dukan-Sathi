import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:printing/printing.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class InvoicePdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String invoiceNumber;
  final String caption;

  const InvoicePdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.invoiceNumber,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Elegant decorative glass glow in dark mode
          if (isDarkMode)
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              children: [
                // Premium header matching Glassmorphic Design System
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkGlass : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? AppColors.darkGlassBorder : AppColors.lightGlassBorder.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : AppColors.lightPrimarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Iconsax.arrow_left_2,
                            color: isDarkMode ? Colors.white : AppColors.lightOnSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoiceNumber,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : AppColors.lightOnSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "Tax Invoice Generated Successfully",
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : AppColors.lightOnSurface.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),

                // Main PDF Viewer Container
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkGlass : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDarkMode ? AppColors.darkGlassBorder : AppColors.lightGlassBorder.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: PdfPreview(
                        build: (format) => pdfBytes,
                        allowPrinting: true,
                        allowSharing: true,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        // Override standard buttons with modern design
                        pdfPreviewPageDecoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        actions: [
                          PdfPreviewAction(
                            icon: Icon(
                              Iconsax.close_circle, 
                              color: isDarkMode ? Colors.white : AppColors.lightOnSurface
                            ),
                            onPressed: (context, build, pageFormat) {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
