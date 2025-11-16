import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🎨 Enhanced Animated Logo Widget with Spectacular Effects
/// 
/// Features:
/// - 3D floating and rotation effect
/// - Multiple pulsing corona rings
/// - Particle shimmer system
/// - Dynamic color shifting
/// - Bounce entrance animation
/// - Sparkle effects
class AnimatedLogo extends StatefulWidget {
  final double size;
  final String logoAsset;

  const AnimatedLogo({
    super.key,
    this.size = 140,
    this.logoAsset = 'assets/images/logo_transparent.png',
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  // Corona ring controllers
  late AnimationController _coronaController1;
  late AnimationController _coronaController2;
  late AnimationController _coronaController3;
  
  // 3D float and rotation controller
  late AnimationController _floatController;
  late AnimationController _rotateController;
  
  // Entrance animation controller
  late AnimationController _entranceController;
  
  // Shimmer particle controller
  late AnimationController _shimmerController;
  
  // Sparkle controller
  late AnimationController _sparkleController;
  
  // Corona animations
  late Animation<double> _coronaScale1;
  late Animation<double> _coronaScale2;
  late Animation<double> _coronaScale3;
  
  late Animation<double> _coronaOpacity1;
  late Animation<double> _coronaOpacity2;
  late Animation<double> _coronaOpacity3;
  
  // 3D animations
  late Animation<double> _floatOffset;
  late Animation<double> _rotateAngle;
  
  // Entrance animations
  late Animation<double> _entranceScale;
  late Animation<double> _entranceOpacity;
  
  // Color shift animation
  late Animation<Color?> _colorShift;

  // Random sparkle positions
  final List<Offset> _sparklePositions = [];

  @override
  void initState() {
    super.initState();
    
    // Generate random sparkle positions
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) + random.nextDouble() * 0.5;
      final distance = 0.6 + random.nextDouble() * 0.2;
      _sparklePositions.add(Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      ));
    }
    
    // Initialize controllers
    _initializeControllers();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeControllers() {
    // Corona controllers (pulsing rings)
    _coronaController1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _coronaController2 = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _coronaController3 = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // 3D float controller (slow up and down)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    
    // Rotation controller (subtle tilt)
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );
    
    // Entrance controller (bounce in)
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Shimmer controller (particle effects)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Sparkle controller
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  void _initializeAnimations() {
    // Corona scale animations
    _coronaScale1 = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _coronaController1, curve: Curves.easeOut),
    );
    
    _coronaScale2 = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(parent: _coronaController2, curve: Curves.easeOut),
    );
    
    _coronaScale3 = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _coronaController3, curve: Curves.easeOut),
    );

    // Corona opacity animations
    _coronaOpacity1 = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _coronaController1, curve: Curves.easeOut),
    );
    
    _coronaOpacity2 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _coronaController2, curve: Curves.easeOut),
    );
    
    _coronaOpacity3 = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _coronaController3, curve: Curves.easeOut),
    );
    
    // Float animation (gentle up and down)
    _floatOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    // Rotation animation (subtle tilt)
    _rotateAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));
    
    // Entrance bounce animation
    _entranceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut,
      ),
    );
    
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    
    // Color shift animation (gold to orange to gold)
    _colorShift = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFD4AF37), // Gold
          end: const Color(0xFFFF8C00),   // Orange
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFFF8C00), // Orange
          end: const Color(0xFFD4AF37),   // Gold
        ),
        weight: 1,
      ),
    ]).animate(_rotateController);
  }

  void _startAnimations() {
    // Start entrance animation
    _entranceController.forward();
    
    // Start corona animations with staggered delays
    _coronaController1.repeat();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _coronaController2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _coronaController3.repeat();
    });
    
    // Start 3D animations
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _floatController.repeat(reverse: true);
        _rotateController.repeat();
      }
    });
    
    // Start shimmer animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _shimmerController.repeat();
    });
    
    // Start sparkle animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _sparkleController.repeat();
    });
  }

  @override
  void dispose() {
    _coronaController1.dispose();
    _coronaController2.dispose();
    _coronaController3.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _entranceController.dispose();
    _shimmerController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.primary;

    return SizedBox(
      width: widget.size * 2.0,
      height: widget.size * 2.0,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceController,
          _floatController,
          _rotateController,
        ]),
        builder: (context, child) {
          return Opacity(
            opacity: _entranceOpacity.value,
            child: Transform.scale(
              scale: _entranceScale.value,
              child: Transform.translate(
                offset: Offset(0, _floatOffset.value),
                child: Transform.rotate(
                  angle: _rotateAngle.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sparkle particles
                      ..._buildSparkles(baseColor),
                      
                      // Third corona ring (outermost, slowest)
                      _buildCoronaRing(
                        controller: _coronaController3,
                        scale: _coronaScale3,
                        opacity: _coronaOpacity3,
                        color: _colorShift.value ?? baseColor,
                        size: widget.size * 1.3,
                        intensity: 0.35,
                      ),
                      
                      // Second corona ring (middle speed)
                      _buildCoronaRing(
                        controller: _coronaController2,
                        scale: _coronaScale2,
                        opacity: _coronaOpacity2,
                        color: _colorShift.value ?? baseColor,
                        size: widget.size * 1.25,
                        intensity: 0.45,
                      ),
                      
                      // First corona ring (innermost, fastest)
                      _buildCoronaRing(
                        controller: _coronaController1,
                        scale: _coronaScale1,
                        opacity: _coronaOpacity1,
                        color: _colorShift.value ?? baseColor,
                        size: widget.size * 1.2,
                        intensity: 0.55,
                      ),
                      
                      // Static glow behind logo
                      _buildStaticGlow(_colorShift.value ?? baseColor),
                      
                      // Shimmer overlay
                      _buildShimmerOverlay(baseColor),
                      
                      // Logo on top with subtle shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_colorShift.value ?? baseColor)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          widget.logoAsset,
                          height: widget.size,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoronaRing({
    required AnimationController controller,
    required Animation<double> scale,
    required Animation<double> opacity,
    required Color color,
    required double size,
    required double intensity,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: opacity.value * intensity),
                  color.withValues(alpha: opacity.value * intensity * 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticGlow(Color color) {
    return Container(
      width: widget.size * 1.2,
      height: widget.size * 1.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildShimmerOverlay(Color baseColor) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _shimmerController.value * math.pi * 2,
          child: Container(
            width: widget.size * 1.4,
            height: widget.size * 1.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,  // ✅ FIX: Make it circular to hide rotating square
              gradient: SweepGradient(
                colors: [
                  Colors.transparent,
                  baseColor.withValues(alpha: 0.1),
                  Colors.transparent,
                  baseColor.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.4, 0.6, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkles(Color baseColor) {
    return _sparklePositions.asMap().entries.map((entry) {
      final index = entry.key;
      final position = entry.value;
      final delay = index * 0.15;
      
      return AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, child) {
          final progress = (_sparkleController.value - delay) % 1.0;
          final opacity = progress < 0.5
              ? progress * 2
              : (1.0 - progress) * 2;
          
          // ✅ FIX: Adjust positioning to keep sparkles closer to logo
          // Center the sparkle positions properly within the container
          final containerSize = widget.size * 2.0;
          final sparkleRadius = widget.size * 0.65;  // Keep sparkles closer
          
          return Positioned(
            left: (containerSize / 2) + position.dx * sparkleRadius - 4,  // Center and offset by dot size
            top: (containerSize / 2) + position.dy * sparkleRadius - 4,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor,
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}
