import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'navigation_screen.dart';

/// Screen 3: Hospital Selection
/// Vertical list of hospital cards with ETA, availability, and Navigate button.
class HospitalSelectionScreen extends StatelessWidget {
  const HospitalSelectionScreen({super.key});

  static const _hospitals = [
    {
      'name': 'City General Hospital',
      'address': '1200 Medical Center Dr, Downtown',
      'eta': '4 min',
      'distance': '2.1 km',
      'beds': 8,
      'available': true,
    },
    {
      'name': 'St. Mary\'s Medical Center',
      'address': '890 Healthcare Ave, Westside',
      'eta': '7 min',
      'distance': '3.8 km',
      'beds': 3,
      'available': true,
    },
    {
      'name': 'Regional Trauma Center',
      'address': '450 Emergency Blvd, Midtown',
      'eta': '12 min',
      'distance': '6.2 km',
      'beds': 0,
      'available': false,
    },
    {
      'name': 'University Hospital',
      'address': '700 University Pkwy, North Campus',
      'eta': '15 min',
      'distance': '8.5 km',
      'beds': 12,
      'available': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Hospital',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Nearest facilities with capacity',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Summary strip ───
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'Patient data sent • ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      'Critical condition',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Hospital list ───
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.sm,
                ),
                itemCount: _hospitals.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  final h = _hospitals[index];
                  return HospitalCard(
                    name: h['name'] as String,
                    address: h['address'] as String,
                    eta: h['eta'] as String,
                    distance: h['distance'] as String,
                    bedsAvailable: h['beds'] as int,
                    isAvailable: h['available'] as bool,
                    onNavigate: (h['available'] as bool)
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NavigationScreen(
                                  hospitalName: h['name'] as String,
                                  eta: h['eta'] as String,
                                ),
                              ),
                            );
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
