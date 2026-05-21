import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;
  bool _shouldShow = false;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
    _subscription = _connectivityService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          if (!isOnline) {
            _shouldShow = true;
            _wasOffline = true;
          } else {
            if (_wasOffline) {
              _shouldShow = true;
              // Hide after 3 seconds when back online
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() => _shouldShow = false);
                }
              });
            } else {
              _shouldShow = false;
            }
          }
        });
      }
    });
  }

  Future<void> _checkInitialState() async {
    final online = await _connectivityService.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = online;
        _shouldShow = !online;
        if (!online) _wasOffline = true;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _isOnline
              ? AppColors.success.withOpacity(0.9)
              : AppColors.warning.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOnline ? Iconsax.wifi : Iconsax.wifi_square,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _isOnline
                  ? "Back Online! Syncing pending offline transactions..."
                  : "Offline Mode active. All sales and edits are saved locally.",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut),
    );
  }
}
