import 'package:flutter/material.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../common_widgets/custom_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../quran/ui/quran_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            ProfileHeader(
              userName: 'Abdullah',
              greeting: '${AppHelpers.getIslamicGreeting()}\n${AppHelpers.getTimeBasedGreeting()}',
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Islamic Carousel Section
                  const _CarouselSection(),

                  const SizedBox(height: 24),

                  // Features Grid Section
                  const _FeaturesGridSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselSection extends StatelessWidget {
  const _CarouselSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Inspiration',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: AppConstants.carouselHeight,
          child: PageView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.secondary.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getCarouselContent(index),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getCarouselContent(int index) {
    switch (index) {
      case 0:
        return '"And whoever relies upon Allah - then He is sufficient for him."';
      case 1:
        return '"Indeed, with hardship comes ease."';
      case 2:
        return '"And Allah is the best of planners."';
      default:
        return '"Verily, in the remembrance of Allah do hearts find rest."';
    }
  }
}

class _FeaturesGridSection extends StatelessWidget {
  const _FeaturesGridSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Islamic Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: AppConstants.homeGridColumns,
          crossAxisSpacing: AppConstants.homeGridSpacing,
          mainAxisSpacing: AppConstants.homeGridSpacing,
          children: [
            FeatureCard(
              title: AppConstants.tasbihFeature,
              icon: Icons.radio_button_checked,
              onTap: () => _navigateToFeature(context, 'Tasbih'),
            ),
            FeatureCard(
              title: AppConstants.hadithFeature,
              icon: Icons.menu_book,
              onTap: () => _navigateToFeature(context, 'Hadith'),
            ),
            FeatureCard(
              title: AppConstants.duaFeature,
              icon: Icons.favorite,
              onTap: () => _navigateToFeature(context, 'Dua'),
            ),
            FeatureCard(
              title: AppConstants.quranFeature,
              icon: Icons.book,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuranScreen()),
              ),
            ),
            FeatureCard(
              title: AppConstants.wallpaperFeature,
              icon: Icons.wallpaper,
              onTap: () => _navigateToFeature(context, 'Wallpaper'),
            ),
            FeatureCard(
              title: AppConstants.donateFeature,
              icon: Icons.volunteer_activism,
              iconColor: AppColors.secondary,
              onTap: () => _navigateToFeature(context, 'Donate'),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToFeature(BuildContext context, String featureName) {
    AppHelpers.showSnackBar(context, '$featureName feature coming soon!');
    // TODO: Navigate to respective feature screens
  }
}
