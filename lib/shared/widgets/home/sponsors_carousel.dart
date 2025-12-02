import 'package:flutter/material.dart';
import '../../../data/models/sponsor_model.dart';
import '../../../data/repositories/main_api_repository.dart';
import '../sponsors/sponsor_detail_dialog.dart';

/// Sponsors Carousel Widget
/// 
/// Displays a horizontal scrolling carousel of club sponsors
/// Sorted by priority (lower priority number = higher importance)
class SponsorsCarousel extends StatefulWidget {
  const SponsorsCarousel({super.key});

  @override
  State<SponsorsCarousel> createState() => _SponsorsCarouselState();
}

class _SponsorsCarouselState extends State<SponsorsCarousel> {
  final _repository = MainApiRepository();
  List<Sponsor> _sponsors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSponsors();
  }

  Future<void> _loadSponsors() async {
    try {
      final response = await _repository.getSponsors();
      
      final List<Sponsor> sponsors = [];
      if (response is List) {
        for (var item in response) {
          try {
            final sponsor = Sponsor.fromJson(item as Map<String, dynamic>);
            sponsors.add(sponsor);
          } catch (e) {
            print('⚠️ [SponsorsCarousel] Error parsing sponsor: $e');
          }
        }
      }

      // Sort by priority (lower number = higher priority)
      sponsors.sort((a, b) => a.priority.compareTo(b.priority));

      if (mounted) {
        setState(() {
          _sponsors = sponsors;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [SponsorsCarousel] Error: $e');
      if (mounted) {
        setState(() {
          _sponsors = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showSponsorDetails(Sponsor sponsor) {
    showDialog(
      context: context,
      builder: (context) => SponsorDetailDialog(sponsor: sponsor),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sponsors.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _sponsors.length,
        itemBuilder: (context, index) {
          final sponsor = _sponsors[index];
          return _SponsorCard(
            sponsor: sponsor,
            onTap: () => _showSponsorDetails(sponsor),
          );
        },
      ),
    );
  }
}

class _SponsorCard extends StatelessWidget {
  final Sponsor sponsor;
  final VoidCallback onTap;

  const _SponsorCard({
    required this.sponsor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sponsor Logo
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      sponsor.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.business,
                            size: 48,
                            color: colors.onSurfaceVariant,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Sponsor Title
                Text(
                  sponsor.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Tap to learn more hint
                Text(
                  'Tap to learn more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
