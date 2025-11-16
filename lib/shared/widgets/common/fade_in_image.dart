import 'package:flutter/material.dart';

/// Fade-in image widget with progressive loading
/// Provides smooth image loading experience with placeholders
class FadeInImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeDuration;

  const FadeInImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeInImage> createState() => _FadeInImageState();
}

class _FadeInImageState extends State<FadeInImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget content;

    if (_hasError) {
      // Error state
      content = widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: colors.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
          );
    } else if (_isLoading) {
      // Loading state
      content = widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: colors.surfaceContainerHighest,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
    } else {
      // Image loaded - show with fade animation
      content = FadeTransition(
        opacity: _animation,
        child: Image.network(
          widget.imageUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          // Background placeholder during loading
          if (_isLoading || _hasError) content,
          
          // Actual image
          Image.network(
            widget.imageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                // Image loaded
                if (_isLoading) {
                  setState(() => _isLoading = false);
                  _controller.forward();
                }
                return child;
              }
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              if (!_hasError) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

/// Cached network image with fade-in effect
/// Simpler alternative when caching is not a priority
class SimpleFadeInImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SimpleFadeInImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            child: child,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          );
        },
      ),
    );
  }
}

/// Avatar image with fade-in effect
class FadeInAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;

  const FadeInAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          fallbackText ?? '?',
          style: TextStyle(fontSize: radius * 0.6),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        // Fallback handled by CircleAvatar
      },
      child: null, // Remove child to show image
    );
  }
}
