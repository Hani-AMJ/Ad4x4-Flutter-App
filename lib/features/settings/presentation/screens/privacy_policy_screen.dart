import 'package:flutter/material.dart';

/// Privacy Policy Screen
/// Displays AD4x4 Privacy Policy (UAE-Compliant)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'AD4x4.com Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UAE-Compliant | Effective: January 1, 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Governed by: UAE Federal Decree-Law No. 45 of 2021 on Personal Data Protection (PDPL)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              theme,
              colors,
              'Introduction',
              'This Privacy Policy explains how the Abu Dhabi Off-Road Club ("AD4x4", "the Club", "we", "our", or "us") collects, processes, '
              'stores, shares, and protects your personal data when you register on AD4x4.com, use our mobile applications, or participate '
              'in Club events. By using AD4x4 platforms, you consent to the practices described in this policy.\n\n'
              'AD4x4 is committed to protecting your personal information in accordance with UAE data protection laws while ensuring that '
              'necessary data is made available to support Club operations, community transparency, and off-road safety.',
            ),

            _buildNumberedSection(theme, colors, '1', 'Information We Collect',
              'We collect personal data you provide during registration, profile updates, event participation, and gallery uploads. '
              'This may include:\n\n'
              '• Full name\n'
              '• Username\n'
              '• Email address\n'
              '• Phone number\n'
              '• Vehicle details (brand, model, color, year, image)\n'
              '• Date of birth\n'
              '• Gender and nationality\n'
              '• Emergency contact details\n'
              '• City of residence\n'
              '• Profile picture (avatar)\n'
              '• Trip participation history and driving level\n'
              '• Photos or videos you upload to the AD4x4 Gallery\n'
              '• Device information and location (when using app features)',
            ),

            _buildNumberedSection(theme, colors, '2', 'Purpose of Data Collection',
              'We use personal data to operate the Club, maintain safety, verify member identities, and ensure proper event management. '
              'Your information is used for:\n\n'
              '• Membership registration and verification\n'
              '• Displaying your profile publicly on AD4x4.com and in the mobile app\n'
              '• Trip creation, registration, safety briefings, and attendance records\n'
              '• Skill progression, logbook management, and promotion eligibility\n'
              '• Communication via push notifications, SMS, or email\n'
              '• Displaying your uploaded photos publicly in galleries linked to trips\n'
              '• Safety, emergency contact, and recovery operations\n'
              '• Moderation, security, and compliance with UAE laws',
            ),

            _buildImportantNotice(
              theme,
              colors,
              'Publicly Visible Information',
              'As part of being an active member of AD4x4, certain profile details will be publicly visible to other members and visitors. '
              'These include:\n\n'
              '• Username\n'
              '• First name and initial of last name\n'
              '• Vehicle brand, model, year, and color\n'
              '• Driving level and number of trips attended\n'
              '• Profile picture\n'
              '• Photos you upload to the AD4x4 Gallery\n'
              '• Your participation in trips (e.g., registered, checked-in)\n\n'
              'By joining the Club, you acknowledge and accept that this information will be public as it is essential to Club operations, '
              'transparency, and community trust.',
            ),

            _buildNumberedSection(theme, colors, '4', 'Photos and Media Uploads',
              'Any images or videos you upload to AD4x4 trip galleries, personal galleries, or shared community albums will be publicly visible. '
              'These uploads may appear:\n\n'
              '• On trip pages\n'
              '• In user profiles\n'
              '• In the main AD4x4 Gallery\n'
              '• In promotional materials (with prior Club approval)\n\n'
              'By uploading media, you grant AD4x4 a non-exclusive right to display, archive, or promote the content as part of Club activities. '
              'You must ensure you own the rights to the content you upload.',
            ),

            _buildNumberedSection(theme, colors, '5', 'Legal Basis for Data Processing',
              'AD4x4 processes your data under the following legal bases:\n\n'
              '• Your consent when registering or uploading content\n'
              '• Legitimate interests in operating the Club and ensuring safety\n'
              '• Compliance with applicable UAE laws and safety regulations',
            ),

            _buildNumberedSection(theme, colors, '6', 'Data Sharing',
              'We may share your personal data with:\n\n'
              '• Club marshals and event leaders for safety and trip management\n'
              '• Emergency services in case of incidents\n'
              '• Authorized IT service providers maintaining our systems\n'
              '• Law enforcement or government authorities when required by UAE law\n\n'
              'We do NOT sell or rent your personal information to any third party.',
            ),

            _buildNumberedSection(theme, colors, '7', 'Data Storage and Security',
              'We store personal data securely on servers located within the UAE or approved international locations in compliance with UAE data '
              'transfer regulations. We implement technical and administrative measures to protect your data from unauthorized access, '
              'alteration, or misuse. However, no system is 100% secure, and we cannot guarantee absolute protection from cyber threats.',
            ),

            _buildNumberedSection(theme, colors, '8', 'Data Retention',
              'Your personal data will be retained as long as you maintain an active membership or as required by UAE legal or operational '
              'obligations. Media uploads may remain visible indefinitely unless deleted by you or upon a valid request.',
            ),

            _buildNumberedSection(theme, colors, '9', 'Member Rights Under UAE Law',
              'Under the UAE PDPL, you have the right to:\n\n'
              '• Access your personal data\n'
              '• Request correction of inaccurate information\n'
              '• Request deletion of your data (unless required for Club operations)\n'
              '• Withdraw consent for non-essential processing\n'
              '• Request information about how your data is processed\n\n'
              'Some rights may be limited when data is essential for Club safety, operations, or historical recordkeeping.',
            ),

            _buildNumberedSection(theme, colors, '10', 'Children\'s Privacy',
              'Members under 18 years old require parental or guardian consent. '
              'Guardians are responsible for the accuracy of the minor\'s data and for monitoring their participation.',
            ),

            _buildNumberedSection(theme, colors, '11', 'Cookies and Tracking',
              'AD4x4.com and the mobile app may use cookies or tracking tools to improve user experience, enhance security, '
              'and remember login preferences. You may disable cookies, but some features may not function correctly.',
            ),

            _buildNumberedSection(theme, colors, '12', 'Third-Party Links',
              'AD4x4 platforms may contain links to third-party websites. We are not responsible for their privacy practices. '
              'Users are encouraged to review their respective policies.',
            ),

            _buildNumberedSection(theme, colors, '13', 'Updates to This Policy',
              'We may revise this Privacy Policy to comply with UAE law or improve clarity. Updates will be posted on AD4x4.com. '
              'Continued use of our services constitutes acceptance of any changes.',
            ),

            _buildNumberedSection(theme, colors, '14', 'Contact Information',
              'For questions, data requests, or concerns, contact:\n\n'
              'Email: info@ad4x4.com\n'
              'Subject: "Privacy Policy Inquiry"',
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Owner: AD4x4 Management Committee', style: theme.textTheme.bodySmall),
                  Text('Contact: info@ad4x4.com', style: theme.textTheme.bodySmall),
                  Text('Version: 1.0 (Effective: 2025-01-01)', style: theme.textTheme.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, ColorScheme colors, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedSection(ThemeData theme, ColorScheme colors, String number, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 6),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotice(ThemeData theme, ColorScheme colors, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
