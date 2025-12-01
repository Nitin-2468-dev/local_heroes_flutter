import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/hero_model.dart';
import '../utils/constants.dart';
import 'swipe_indicator.dart';

/// A swipeable hero card widget.
class HeroCard extends StatefulWidget {
  final LocalHero hero;
  final bool isActive;
  final Function(bool) onSwipe; // true = right (keep), false = left (pass)
  final VoidCallback? onTap;

  const HeroCard({
    super.key,
    required this.hero,
    required this.isActive,
    required this.onSwipe,
    this.onTap,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard>
    with TickerProviderStateMixin  {
  Offset _dragOffset = Offset.zero;
  late AnimationController _animationController;
  late Animation<Offset> _returnAnimation;
  AnimationController? _swipeOutController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _returnAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.addListener(() {
      if (_animationController.isAnimating) {
        setState(() {
          _dragOffset = _returnAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _swipeOutController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    // Allow pan detection on all cards
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isActive) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isActive) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.25;

    if (_dragOffset.dx > threshold) {
      // Swipe right - Keep
      _animateOut(true);
    } else if (_dragOffset.dx < -threshold) {
      // Swipe left - Pass
      _animateOut(false);
    } else {
      // Return to center
      _returnToCenter();
    }
  }

  void _animateOut(bool isKeep) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isKeep ? screenWidth * 1.5 : -screenWidth * 1.5;

    // Dispose previous swipe out controller if any
    _swipeOutController?.dispose();
    
    _swipeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    final animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(
      parent: _swipeOutController!,
      curve: Curves.easeOut,
    ));

    _swipeOutController!.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    _swipeOutController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSwipe(isKeep);
        _swipeOutController?.dispose();
        _swipeOutController = null;
      }
    });

    _swipeOutController!.forward();
  }

  void _returnToCenter() {
    _returnAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward(from: 0);
  }

  double get _rotationAngle {
    return _dragOffset.dx / 300 * 0.3; // Max ~17 degrees
  }

  double get _keepIndicatorOpacity {
    return (_dragOffset.dx / 150).clamp(0.0, 1.0);
  }

  double get _passIndicatorOpacity {
    return (-_dragOffset.dx / 150).clamp(0.0, 1.0);
  }

  Color get _overlayColor {
    if (_dragOffset.dx > 20) {
      return AppColors.keepGreen.withValues(alpha: (_dragOffset.dx / 300).clamp(0.0, 0.4));
    } else if (_dragOffset.dx < -20) {
      return AppColors.passRed.withValues(alpha: (-_dragOffset.dx / 300).clamp(0.0, 0.4));
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.65).clamp(500.0, 700.0).toDouble();
    final maxWidth = MediaQuery.of(context).size.width - 32; // 16 padding on each side
    final cardWidth = maxWidth.clamp(0.0, AppDimensions.cardMaxWidth);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      child: Transform.translate(
        offset: widget.isActive ? _dragOffset : Offset.zero,
        child: Transform.rotate(
          angle: widget.isActive ? _rotationAngle : 0,
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main card content with rounded corners
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Image section (55%)
                      Expanded(
                        flex: 55,
                        child: _buildImageSection(),
                      ),
                      // Content section (45%)
                      Expanded(
                        flex: 45,
                        child: _buildContentSection(),
                      ),
                    ],
                  ),
                ),

                // Color overlay on swipe
                if (widget.isActive)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      child: Container(
                        color: _overlayColor,
                      ),
                    ),
                  ),

                // Keep indicator
                if (widget.isActive)
                  Positioned(
                    top: 32,
                    left: 32,
                    child: SwipeIndicator(
                      isKeep: true,
                      opacity: _keepIndicatorOpacity,
                    ),
                  ),

                // Pass indicator
                if (widget.isActive)
                  Positioned(
                    top: 32,
                    right: 32,
                    child: SwipeIndicator(
                      isKeep: false,
                      opacity: _passIndicatorOpacity,
                    ),
                  ),

                // Profile avatar - positioned in front of everything
                Positioned(
                  top: cardHeight * 0.55 - 40, // 55% is image section, avatar at bottom
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildAvatarImage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image or placeholder
        if (widget.hero.imageUrl != null && widget.hero.imageUrl!.isNotEmpty)
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: widget.hero.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            ),
          )
        else
          _buildPlaceholder(),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDBEAFE), // blue-100
            Color(0xFFC7D2FE), // indigo-200
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.hero.initials,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Color(0xFF818CF8), // indigo-400
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Name
              Text(
                widget.hero.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Field badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.hero.field.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio - full text, no truncation
              Text(
                widget.hero.bio,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (widget.hero.imageUrl != null && widget.hero.imageUrl!.isNotEmpty) {
      return SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: widget.hero.imageUrl!,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          placeholder: (context, url) => _buildAvatarPlaceholder(),
          errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
        ),
      );
    }
    return _buildAvatarPlaceholder();
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        widget.hero.initials,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}
