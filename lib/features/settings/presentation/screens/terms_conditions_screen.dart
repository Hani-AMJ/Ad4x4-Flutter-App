import 'package:flutter/material.dart';

/// Terms and Conditions Screen
/// Displays AD4x4 Club Membership Terms and Conditions (UAE-Compliant)
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'AD4x4 Club Membership Terms and Conditions',
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
              'Governing Law: United Arab Emirates Federal Laws and Regulations',
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
              'These Terms and Conditions govern membership and participation in the Abu Dhabi Off-Road Club ("AD4x4" or "the Club"). '
              'By registering on AD4x4.com, participating in any Club event, or engaging in any Club activity, you confirm that you have read, '
              'understood, and agreed to these Terms. These Terms comply with UAE Civil Code and applicable laws concerning liability, '
              'personal safety, and data protection.',
            ),

            _buildNumberedSection(theme, colors, '1', 'Voluntary Participation',
              'You acknowledge that your participation in off-roading activities organized by the Club is voluntary. '
              'You understand that off-roading involves inherent risks—including vehicle damage, personal injury, or death—'
              'and you accept full responsibility for your participation.',
            ),

            _buildNumberedSection(theme, colors, '2', 'Hazardous Nature of Activity',
              'Off-roading is considered a high-risk, extreme sport under UAE standards. '
              'By participating, you confirm your awareness of the associated dangers, including terrain instability, '
              'mechanical failures, and potential rollovers, and agree to assume all such risks personally.',
            ),

            _buildNumberedSection(theme, colors, '3', 'Prohibition of Racing and Timing',
              'Racing, competitive driving, timing, or any form of speed challenge is strictly prohibited in all AD4x4 events. '
              'All drives are recreational and focused on safety, skill improvement, and teamwork.',
            ),

            _buildNumberedSection(theme, colors, '4', 'Simultaneous Participation',
              'You understand that multiple vehicles and participants will be on the same route. '
              'You agree to exercise caution, maintain safe distances, and act responsibly at all times.',
            ),

            _buildNumberedSection(theme, colors, '5', 'Compliance with Safety and Club Rules',
              'You must comply with all instructions, briefings, and safety measures provided by marshals and Club officials. '
              'Non-compliance may result in immediate removal from the event at the discretion of the lead marshal.',
            ),

            _buildNumberedSection(theme, colors, '6', 'Insurance and Liability Disclaimer',
              'The Club, its founders, marshals, and affiliates do not provide personal accident, vehicle, or public liability insurance. '
              'Participants are strongly advised to secure off-road vehicle insurance and personal accident coverage through licensed UAE insurers. '
              'The Club bears no responsibility for damage, loss, or injury during or after any event.',
            ),

            _buildNumberedSection(theme, colors, '7', 'Health and Competence',
              'You declare that you are in good physical and mental health and capable of safely operating a motor vehicle off-road. '
              'You must not participate if you suffer from any medical condition that could impair your performance. '
              'You confirm that you are not under the influence of alcohol, drugs, or any substance that affects judgment or motor skills.',
            ),

            _buildNumberedSection(theme, colors, '8', 'Vehicle Safety and Equipment',
              'You are responsible for ensuring your vehicle is in safe mechanical condition and suitable for off-road use. '
              'Vehicles must have proper recovery points, working seatbelts, and safety gear. '
              'The Club is not liable for any mechanical failure, towing, or recovery costs resulting from your participation.',
            ),

            _buildNumberedSection(theme, colors, '9', 'Driver Licensing and Legal Compliance',
              'You confirm that you possess a valid UAE driver\'s license appropriate for the vehicle you operate. '
              'You agree to comply with all UAE traffic laws, even when operating in off-road or desert areas.',
            ),

            _buildNumberedSection(theme, colors, '10', 'Alcohol and Drug Prohibition',
              'Consumption of alcohol or use of intoxicating substances before or during any Club event is strictly prohibited. '
              'Violation of this clause will result in immediate expulsion and may be reported to relevant UAE authorities.',
            ),

            _buildNumberedSection(theme, colors, '11', 'Liability Waiver and Indemnity',
              'You agree to release and hold harmless AD4x4, its board, founders, marshals, agents, and volunteers from any '
              'liability, claim, or expense arising out of your participation in any Club event. '
              'You further agree to indemnify the Club for any damages or claims made by third parties resulting from your actions or negligence.',
            ),

            _buildNumberedSection(theme, colors, '12', 'Recovery Service Registration',
              'You are required to maintain an active subscription with an authorized off-road recovery service (e.g., IATC, AAA, or equivalent) '
              'to ensure assistance in case of vehicle immobilization or emergencies.',
            ),

            _buildNumberedSection(theme, colors, '13', 'Compliance with Regulations and Disciplinary Actions',
              'All members must respect Club regulations and the authority of marshals during trips. '
              'The Club reserves the right to suspend, revoke, or terminate membership for violations of safety, conduct, or integrity standards.',
            ),

            _buildNumberedSection(theme, colors, '14', 'Prohibition of Unauthorized Groups and Sub-Clubs',
              'Creating or operating parallel groups under the AD4x4 name or using its logo, branding, or digital platforms without written '
              'approval from AD4x4 Management is strictly prohibited. '
              'Any affiliated group or club must obtain written approval and remain in compliance with these Terms and AD4x4 bylaws.',
            ),

            _buildNumberedSection(theme, colors, '15', 'Content and Forum Policy',
              'Members must adhere to UAE Federal Law No. 5 of 2012 (Cybercrime Law) when posting content on Club forums or social media. '
              'Abusive, defamatory, obscene, hateful, or unlawful content is strictly forbidden. '
              'The Club reserves the right to edit, delete, or restrict any content at its sole discretion.',
            ),

            _buildNumberedSection(theme, colors, '16', 'Data Privacy and Protection',
              'AD4x4 collects and processes personal data in accordance with the UAE Federal Decree-Law No. 45 of 2021 on Personal Data Protection. '
              'Personal information is stored securely and used solely for Club operations. '
              'The Club will not sell or share your personal data with third parties without consent, except as required by law or emergency response.',
            ),

            _buildNumberedSection(theme, colors, '17', 'Media Use and Consent',
              'By participating in Club events, you grant AD4x4 permission to photograph, film, or record your participation and '
              'to use such media for promotional or archival purposes across all platforms, without financial compensation.',
            ),

            _buildNumberedSection(theme, colors, '18', 'Parental Consent for Minors',
              'Participants under the age of 18 must have written consent from a parent or legal guardian. '
              'The guardian assumes full responsibility for the minor\'s participation and safety.',
            ),

            _buildNumberedSection(theme, colors, '19', 'Governing Law and Jurisdiction',
              'These Terms are governed by the laws of the United Arab Emirates. '
              'Any disputes arising from or related to Club activities shall be subject to the exclusive jurisdiction of the Abu Dhabi Courts.',
            ),

            _buildNumberedSection(theme, colors, '20', 'Acknowledgment and Acceptance',
              'By registering on AD4x4.com or participating in any AD4x4 event, you acknowledge that you have read, understood, and voluntarily '
              'accepted these Terms and Conditions. You also acknowledge that this constitutes a legally binding agreement between you and the Club.',
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
}
