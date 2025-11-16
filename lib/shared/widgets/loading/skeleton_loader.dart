import 'package:flutter/material.dart';

/// Skeleton loader widget with shimmer animation effect
/// Provides content-aware loading placeholders for better UX
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colors.surfaceContainerHighest,
                colors.surfaceContainerHighest.withValues(alpha: 0.5),
                colors.surfaceContainerHighest,
              ],
              stops: [
                (_animation.value - 1.0).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1.0).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for trip card (matches trip_card.dart design)
class SkeletonTripCard extends StatelessWidget {
  const SkeletonTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const SkeletonLoader(width: 200, height: 20),
            const SizedBox(height: 8),
            
            // Subtitle
            const SkeletonLoader(width: 150, height: 14),
            const SizedBox(height: 16),
            
            // Info row
            Row(
              children: [
                const SkeletonLoader(width: 80, height: 14),
                const SizedBox(width: 16),
                const SkeletonLoader(width: 60, height: 14),
                const Spacer(),
                SkeletonLoader(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for list item
class SkeletonListTile extends StatelessWidget {
  final bool hasAvatar;
  final bool hasTrailing;

  const SkeletonListTile({
    super.key,
    this.hasAvatar = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            if (hasAvatar) ...[
              SkeletonLoader(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(width: 16),
            ],
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 14,
                  ),
                ],
              ),
            ),
            
            // Trailing
            if (hasTrailing) ...[
              const SizedBox(width: 16),
              const SkeletonLoader(width: 24, height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for grid item
class SkeletonGridItem extends StatelessWidget {
  const SkeletonGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          const Expanded(
            child: SkeletonLoader(
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for profile header
class SkeletonProfileHeader extends StatelessWidget {
  const SkeletonProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        SkeletonLoader(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.circular(50),
        ),
        const SizedBox(height: 16),
        
        // Name
        const SkeletonLoader(width: 150, height: 24),
        const SizedBox(height: 8),
        
        // Subtitle
        const SkeletonLoader(width: 120, height: 16),
        const SizedBox(height: 24),
        
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(),
            _buildStatItem(),
            _buildStatItem(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem() {
    return const Column(
      children: [
        SkeletonLoader(width: 60, height: 28),
        SizedBox(height: 4),
        SkeletonLoader(width: 80, height: 14),
      ],
    );
  }
}

/// Skeleton loader for dashboard stat card
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoader(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
                const Spacer(),
                const SkeletonLoader(width: 16, height: 16),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonLoader(width: 100, height: 14),
            const SizedBox(height: 4),
            const SkeletonLoader(width: 60, height: 32),
            const SizedBox(height: 4),
            const SkeletonLoader(width: 80, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Helper method to show skeleton loaders in ListView
class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;

  const SkeletonListView({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Helper method to show skeleton loaders in GridView
class SkeletonGridView extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;

  const SkeletonGridView({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    required this.itemBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
