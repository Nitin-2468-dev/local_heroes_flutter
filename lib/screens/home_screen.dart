import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/heroes_provider.dart';
import '../utils/constants.dart';
import '../widgets/hero_card.dart';
import '../widgets/custom_button.dart';
import 'kept_list_screen.dart';

/// Home screen with the main swipe interface.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<HeroesProvider>(
        builder: (context, provider, _) {
          // Trigger confetti when needed
          if (provider.showConfetti) {
            _confettiController.play();
          }

          return Stack(
            children: [
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context, provider),

                    // Main area
                    Expanded(
                      child: provider.isFinished
                          ? _buildFinishedState(context, provider)
                          : _buildCardStack(context, provider),
                    ),

                    // Navigation bar
                    _buildNavBar(context, provider),
                  ],
                ),
              ),

              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: AppColors.confettiColors,
                  numberOfParticles: 30,
                  gravity: 0.2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HeroesProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and title
          Row(
            children: [
              _buildAppLogo(),
              const SizedBox(width: 12),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          // Kept button
          GestureDetector(
            onTap: () => _openKeptList(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    AppStrings.keep,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.keepGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.keepGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.keptList.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.keepGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 24,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardStack(BuildContext context, HeroesProvider provider) {
    final visibleCards = provider.visibleCards;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cards - render from bottom to top
                for (int i = 0; i < visibleCards.length; i++)
                  Positioned.fill(
                    child: Center(
                      child: Transform.scale(
                        scale: i == visibleCards.length - 1 ? 1.0 : 0.95,
                        child: HeroCard(
                          key: ValueKey(visibleCards[i].id),
                          hero: visibleCards[i],
                          isActive: i == visibleCards.length - 1,
                          onSwipe: (isKeep) {
                            provider.onSwipe(
                              isKeep
                                  ? SwipeDirection.right
                                  : SwipeDirection.left,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Action buttons: Pass - Undo - Keep
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLG,
            vertical: AppDimensions.paddingMD,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pass button (left)
              _buildActionButton(
                icon: Icons.close,
                color: AppColors.passRed,
                label: AppStrings.pass,
                onTap: provider.isFinished
                    ? null
                    : () => provider.onSwipe(SwipeDirection.left),
                size: 56,
              ),

              // Undo button (center)
              _buildActionButton(
                icon: Icons.undo,
                color: AppColors.textSecondary,
                label: 'Undo',
                onTap: provider.canUndo ? provider.undo : null,
                size: 48,
                isUndo: true,
              ),

              // Keep button (right)
              _buildActionButton(
                icon: Icons.check,
                color: AppColors.keepGreen,
                label: AppStrings.keep,
                onTap: provider.isFinished
                    ? null
                    : () => provider.onSwipe(SwipeDirection.right),
                size: 56,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedState(BuildContext context, HeroesProvider provider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingLG),
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.layers_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.deckComplete,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.heroesKept.replaceAll(
                '{count}',
                '${provider.keptList.length}',
              ),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: AppStrings.restartDeck,
              variant: ButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: provider.restart,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: AppStrings.viewKeptList,
              variant: ButtonVariant.primary,
              fullWidth: true,
              icon: const Icon(Icons.bookmark_outline, size: 18),
              onPressed: () => _openKeptList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, HeroesProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.layers_outlined,
            label: AppStrings.deck,
            onTap: provider.restart,
          ),
          _buildNavItem(
            icon: Icons.bookmark_outline,
            label: AppStrings.keptList,
            onTap: () => _openKeptList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        highlightColor: AppColors.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onTap,
    required double size,
    bool isUndo = false,
  }) {
    final isEnabled = onTap != null;
    final buttonColor = isEnabled ? color : color.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: color.withValues(alpha: 0.3),
        highlightColor: color.withValues(alpha: 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isUndo
                    ? (isEnabled
                        ? AppColors.surfaceDark
                        : AppColors.surfaceDark.withValues(alpha: 0.5))
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isUndo
                    ? null
                    : Border.all(
                        color: buttonColor,
                        width: 3,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isEnabled
                        ? color.withValues(alpha: 0.3)
                        : Colors.transparent,
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isUndo
                    ? (isEnabled ? AppColors.textPrimary : AppColors.textMuted)
                    : buttonColor,
                size: size * 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEnabled ? buttonColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openKeptList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const KeptListScreen(),
      ),
    );
  }
}
