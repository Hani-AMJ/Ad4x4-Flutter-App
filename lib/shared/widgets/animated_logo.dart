import 'package:flutter/material.dart';

/// Animated Logo Widget with Pulsing Corona Effect
/// 
/// Features:
/// - Multiple pulsing rings in gold accent colors
/// - Smooth animation loop
/// - Customizable size
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
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  
  late Animation<double> _scale1;
  late Animation<double> _scale2;
  late Animation<double> _scale3;
  
  late Animation<double> _opacity1;
  late Animation<double> _opacity2;
  late Animation<double> _opacity3;

  @override
  void initState() {
    super.initState();
    
    // Three animation controllers with different durations for layered effect
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Scale animations - start from logo size and expand outward
    _scale1 = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeOut),
    );
    
    _scale2 = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeOut),
    );
    
    _scale3 = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(parent: _controller3, curve: Curves.easeOut),
    );

    // Opacity animations - fade out as they expand
    _opacity1 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeOut),
    );
    
    _opacity2 = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeOut),
    );
    
    _opacity3 = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _controller3, curve: Curves.easeOut),
    );

    // Start animations with staggered delays
    _controller1.repeat();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller3.repeat();
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goldColor = theme.colorScheme.primary; // Gold accent color

    return SizedBox(
      width: widget.size * 1.8,
      height: widget.size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Third corona ring (outermost, slowest)
          AnimatedBuilder(
            animation: _controller3,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale3.value,
                child: Container(
                  width: widget.size * 1.2,
                  height: widget.size * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        goldColor.withValues(alpha: _opacity3.value * 0.3),
                        goldColor.withValues(alpha: _opacity3.value * 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Second corona ring (middle speed)
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale2.value,
                child: Container(
                  width: widget.size * 1.2,
                  height: widget.size * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        goldColor.withValues(alpha: _opacity2.value * 0.4),
                        goldColor.withValues(alpha: _opacity2.value * 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // First corona ring (innermost, fastest)
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale1.value,
                child: Container(
                  width: widget.size * 1.2,
                  height: widget.size * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        goldColor.withValues(alpha: _opacity1.value * 0.5),
                        goldColor.withValues(alpha: _opacity1.value * 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Static glow behind logo (subtle base layer)
          Container(
            width: widget.size * 1.15,
            height: widget.size * 1.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  goldColor.withValues(alpha: 0.15),
                  goldColor.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          
          // Logo on top
          Image.asset(
            widget.logoAsset,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
