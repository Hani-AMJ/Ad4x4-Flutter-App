import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help & Support Screen
/// Provides contact information and support resources for AD4x4 members
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'We\'re Here to Help',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get assistance with your AD4x4 membership, trips, or technical issues',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Contact Methods
            _buildContactCard(
              context,
              theme,
              colors,
              Icons.email,
              'Email Support',
              'info@ad4x4.com',
              'For general inquiries, membership questions, or technical support',
              () => _launchEmail(context, 'info@ad4x4.com'),
            ),

            const SizedBox(height: 16),

            _buildContactCard(
              context,
              theme,
              colors,
              Icons.language,
              'Visit Our Website',
              'www.ad4x4.com',
              'Access the full AD4x4 website for more resources and information',
              () => _launchWebsite(context, 'https://www.ad4x4.com'),
            ),

            const SizedBox(height: 16),

            _buildContactCard(
              context,
              theme,
              colors,
              Icons.groups,
              'Community Forum',
              'AD4x4 Member Forum',
              'Connect with other members, share experiences, and get peer support',
              () => _launchWebsite(context, 'https://www.ad4x4.com/forum'),
            ),

            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              theme,
              colors,
              'How do I register for a trip?',
              'Navigate to the Trips tab, select a trip you\'re interested in, and tap the "Register" button. '
              'Make sure you meet the level requirements and check the trip details before registering.',
            ),

            _buildFAQItem(
              theme,
              colors,
              'What are the different membership levels?',
              'AD4x4 has multiple levels from Newbie to Expert. Your level increases based on trip participation, '
              'skills demonstrated, and marshal evaluations. Higher levels unlock access to more challenging trips.',
            ),

            _buildFAQItem(
              theme,
              colors,
              'How do I update my vehicle information?',
              'Go to Settings > Profile, then scroll to the Vehicle Information section to update your vehicle details. '
              'This information helps marshals plan trips and ensure your vehicle is suitable.',
            ),

            _buildFAQItem(
              theme,
              colors,
              'What should I bring on a trip?',
              'Essential items include: valid UAE driver\'s license, recovery gear, spare tire, first aid kit, plenty of water, '
              'sun protection, and appropriate clothing. Check the specific trip requirements for additional items.',
            ),

            _buildFAQItem(
              theme,
              colors,
              'How do I contact a marshal?',
              'You can find marshal contact information on each trip\'s detail page. For general marshal inquiries, '
              'email info@ad4x4.com with the subject "Marshal Inquiry".',
            ),

            _buildFAQItem(
              theme,
              colors,
              'What if I need to cancel my registration?',
              'Navigate to the trip detail page and tap "Cancel Registration". Please cancel as early as possible '
              'so your spot can be offered to waitlisted members. Frequent last-minute cancellations may affect your standing.',
            ),

            const SizedBox(height: 32),

            // Emergency Contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emergency, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Emergency Assistance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you experience an emergency during a trip:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Contact your trip marshal immediately\n'
                    '2. Call UAE Emergency Services: 999\n'
                    '3. Contact your recovery service (IATC, AAA, etc.)\n'
                    '4. Stay with your vehicle if safe to do so',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Info
            Text(
              'App Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(theme, 'App Version', '1.0.0'),
            _buildInfoRow(theme, 'Platform', 'Flutter'),
            _buildInfoRow(theme, 'Last Updated', 'January 2025'),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    IconData icon,
    String title,
    String subtitle,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(ThemeData theme, ColorScheme colors, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 0),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(
          question,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email, queryParameters: {
      'subject': 'AD4x4 Support Request',
    });
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email app. Please email: $email')),
        );
      }
    }
  }

  Future<void> _launchWebsite(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $url')),
        );
      }
    }
  }
}
