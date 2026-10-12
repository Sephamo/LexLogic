import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Keep this value in sync with the version in pubspec.yaml.
const String policyCheckAppVersion = '1.0.0';

// Replace these sentences with verified contact details when available.
const String policyCheckSupportContact =
    'For help with this demonstration, contact the LexLogic project '
    'representative using the verified contact details supplied with the app.';
const String policyCheckPrivacyContact =
    'For a personal-information request, contact the LexLogic project '
    'representative through the verified project contact channel. '
    'Describe your request without sending passwords or OTP codes.';

enum SupportInfoPage { helpCenter, termsOfService, privacyPolicy, appVersion }

/// Opens a readable, scrollable support popup without registering a route.
Future<void> showSupportInfoDialog(
  BuildContext context, {
  required SupportInfoPage page,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _SupportInfoDialog(content: _contentFor(page)),
  );
}

class _SupportContent {
  final String title;
  final IconData icon;
  final String introduction;
  final List<_SupportSection> sections;
  final List<_OfficialReference> references;

  const _SupportContent({
    required this.title,
    required this.icon,
    required this.introduction,
    required this.sections,
    this.references = const [],
  });
}

class _SupportSection {
  final String heading;
  final String text;
  final List<String> points;

  const _SupportSection({
    required this.heading,
    this.text = '',
    this.points = const [],
  });
}

class _OfficialReference {
  final String title;
  final String url;

  const _OfficialReference(this.title, this.url);
}

const _popiaAct = _OfficialReference(
  'POPIA: South African Government',
  'https://www.gov.za/documents/protection-personal-information-act',
);
const _popiaGuidance = _OfficialReference(
  'POPIA guidance and request forms',
  'https://inforegulator.org.za/popia/',
);
const _regulatorComplaints = _OfficialReference(
  'Information Regulator: complaints',
  'https://inforegulator.org.za/complaints/',
);

// Service purpose and workflow follow the supplied LexLogic Phase 1 submission.
// Legal summaries were checked against the official Act and Regulator sources
// on 10 October 2026. This is content for the academic prototype.
_SupportContent _contentFor(SupportInfoPage page) {
  switch (page) {
    case SupportInfoPage.helpCenter:
      return const _SupportContent(
        title: 'Help Center',
        icon: Icons.help_outline,
        introduction:
            'PolicyCheck SA helps you inspect insurance policy information '
            'linked to your identity and report registrations you do not '
            'recognise. It brings available records into one place.',
        sections: [
          _SupportSection(
            heading: 'Getting started',
            points: [
              'Sign in with your own account and keep your name, SA ID number '
                  'and phone details accurate.',
              'Complete any identity checks requested before inspecting '
                  'policy records. Keep your OTP codes private.',
              'Use Dashboard > View My Policies to review the available '
                  'policies linked to your account.',
            ],
          ),
          _SupportSection(
            heading: 'Understanding lookup results',
            text:
                'Where a lookup status is shown, Pending means responses '
                'are outstanding, Partial means some responses are available, '
                'and Complete means the requested checks have finished. '
                'Coverage depends on the participating insurers and records '
                'available to your instance. A result showing no policies '
                'does not prove that no policy exists elsewhere.',
          ),
          _SupportSection(
            heading: 'An unfamiliar policy or fraud flag',
            points: [
              'Check the insurer and policy reference before drawing a '
                  'conclusion. A warning indicates a concern to investigate.',
              'Use Dashboard > Report Fraud to describe the issue accurately '
                  'and retain the confirmation shown after submission.',
              'Contact the insurer through its verified official channel '
                  'for confirmation. Reporting in the app does not cancel '
                  'a policy or decide a claim.',
            ],
          ),
          _SupportSection(
            heading: 'Notifications and account activity',
            text:
                'Choose Push Notifications, Fraud Alerts and Policy Renewal '
                'Reminders in Settings > Notifications. If device alerts '
                'are missing, check the app notification permission and '
                'open the dashboard for the latest information. Open Audit '
                'Logs from your profile to review recorded account activity.',
          ),
          _SupportSection(
            heading: 'If information will not load',
            text:
                'Check your internet connection, use the refresh control, '
                'and sign in again if your session has expired. When asking '
                'for assistance, share the error message and a masked '
                'reference instead of your full ID number or login secrets.',
          ),
          _SupportSection(
            heading: 'Contact the project team',
            text: policyCheckSupportContact,
          ),
        ],
      );
    case SupportInfoPage.termsOfService:
      return const _SupportContent(
        title: 'Terms of Service',
        icon: Icons.description_outlined,
        introduction:
            'These terms describe appropriate use of the PolicyCheck SA '
            'academic prototype developed by LexLogic.',
        sections: [
          _SupportSection(
            heading: '1. Purpose of the service',
            text:
                'The platform is a consumer-facing policy verification '
                'intermediary. It helps users inspect available policy '
                'records, identify possible identity misuse and record '
                'fraud concerns. It does not issue insurance policies, '
                'settle claims or act as an insurer.',
          ),
          _SupportSection(
            heading: '2. Authorised use',
            text:
                'Use your own identity information, or act only with '
                'lawful, verifiable authority. Provide accurate information '
                'and authorise each consent-based inspection. Opening '
                'this popup does not grant permission to search another '
                'person\'s records or record consent for optional processing.',
          ),
          _SupportSection(
            heading: '3. Account responsibilities',
            points: [
              'Keep passwords, OTP codes and access to your device private.',
              'Do not impersonate others, bypass access checks, upload '
                  'false evidence or submit knowingly false reports.',
              'Report suspected misuse and keep your account details current.',
            ],
          ),
          _SupportSection(
            heading: '4. Results and reporting',
            text:
                'Results depend on available records and insurer '
                'participation. Multiple policies can be legitimate; a '
                'duplicate or risk flag is not proof of fraud. Confirm '
                'policy ownership, cancellation and claim decisions with '
                'the relevant insurer. An in-app report is not an '
                'automatic finding of wrongdoing.',
          ),
          _SupportSection(
            heading: '5. Demonstration environment',
            text:
                'This is a university project. Demonstration environments '
                'may contain test records or simulated verification steps. '
                'Availability and coverage can vary. Check whether you '
                'are viewing demonstration data before relying on a result.',
          ),
          _SupportSection(
            heading: '6. Privacy and questions',
            text:
                'Read the Privacy Policy for the personal-information '
                'principles and request process. These terms do not '
                'remove rights provided by South African law. '
                '$policyCheckSupportContact',
          ),
        ],
        references: [_popiaAct],
      );
    case SupportInfoPage.privacyPolicy:
      return const _SupportContent(
        title: 'Privacy Policy',
        icon: Icons.privacy_tip_outlined,
        introduction:
            'This notice explains the privacy principles for the '
            'PolicyCheck SA academic prototype. POPIA is South Africa\'s '
            'Protection of Personal Information Act 4 of 2013.',
        sections: [
          _SupportSection(
            heading: 'Information involved',
            text:
                'The project covers account and identity details, policy '
                'lookup records, fraud reports and account activity logs. '
                'An enabled verification process may also request an ID '
                'document or selfie. The details processed depend on the '
                'features used in your demonstration.',
          ),
          _SupportSection(
            heading: 'Purpose and transparency',
            text:
                'The intended purposes are account access, authorised '
                'identity and policy checks, fraud reporting and an audit '
                'trail. Before collection, the operator must explain '
                'the purpose, recipients and whether information is required. '
                'Only relevant information should be requested.',
          ),
          _SupportSection(
            heading: 'Lawful processing and consent',
            text:
                'POPIA permits grounds including consent, contract and '
                'legal duties. Consent can be withdrawn without undoing '
                'earlier lawful processing. A consent-based lookup needs '
                'separate authorisation; notification preferences are '
                'not blanket consent to identity checks or marketing.',
          ),
          _SupportSection(
            heading: 'Your POPIA rights',
            points: [
              'Ask whether information is held about you and request access.',
              'Request correction or deletion where POPIA\'s conditions '
                  'are met.',
              'Object to qualifying processing on the grounds POPIA provides.',
              'Withdraw consent for consent-based processing.',
              'Lodge a privacy complaint with the Information Regulator.',
            ],
          ),
          _SupportSection(
            heading: 'Protection and retention',
            text:
                'Appropriate technical and organisational safeguards '
                'must protect personal information. Records should be '
                'kept only as needed or otherwise lawfully permitted. '
                'A deletion request does not override lawful retention '
                'duties. Biometrics require additional lawful justification.',
          ),
          _SupportSection(
            heading: 'Requests and complaints',
            text:
                '$policyCheckPrivacyContact For a complaint to the '
                'Information Regulator, use its official complaints page '
                'and current eServices process. Objection and correction '
                'or deletion forms are available on its POPIA page.',
          ),
        ],
        references: [_popiaAct, _popiaGuidance, _regulatorComplaints],
      );
    case SupportInfoPage.appVersion:
      return const _SupportContent(
        title: 'About PolicyCheck SA',
        icon: Icons.info_outline,
        introduction:
            'PolicyCheck SA is a LexLogic academic project focused on '
            'insurance transparency and early detection of identity misuse '
            'in South Africa.',
        sections: [
          _SupportSection(
            heading: 'Version',
            text: policyCheckAppVersion,
          ),
          _SupportSection(
            heading: 'Project team',
            text:
                'LexLogic: Mbali Ndlovu, Sephamo Phasha, Rebaona Makhafola '
                'and Kopano Matthews.',
          ),
          _SupportSection(
            heading: 'What the project brings together',
            text:
                'A central policy inspection interface, authorised '
                'identity checks, available insurer responses, fraud '
                'reporting, alerts and an account activity trail. '
                'Features and insurer coverage depend on the demonstration '
                'environment.',
          ),
          _SupportSection(
            heading: 'Need assistance?',
            text: policyCheckSupportContact,
          ),
        ],
      );
  }
}

class _SupportInfoDialog extends StatelessWidget {
  final _SupportContent content;

  const _SupportInfoDialog({required this.content});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: screenHeight * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
              ),
              child: Row(
                children: [
                  Icon(content.icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'PolicyCheck SA',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close support page',
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        content.introduction,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final section in content.sections)
                        _SupportSectionView(section: section),
                      if (content.references.isNotEmpty) ...[
                        const Text(
                          'Official references',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final reference in content.references)
                          _OfficialReferenceView(reference: reference),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Content reviewed: 10 October 2026',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportSectionView extends StatelessWidget {
  final _SupportSection section;

  const _SupportSectionView({required this.section});

  static const _bodyStyle = TextStyle(
    fontSize: 13.5,
    height: 1.55,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 8),
          if (section.text.isNotEmpty)
            SelectableText(section.text, style: _bodyStyle),
          for (final point in section.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: _bodyStyle),
                  Expanded(child: SelectableText(point, style: _bodyStyle)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OfficialReferenceView extends StatefulWidget {
  final _OfficialReference reference;

  const _OfficialReferenceView({required this.reference});

  @override
  State<_OfficialReferenceView> createState() => _OfficialReferenceViewState();
}

class _OfficialReferenceViewState extends State<_OfficialReferenceView> {
  String _copyLabel = 'Copy link';

  Future<void> _copyLink() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.reference.url));
      if (!mounted) return;
      setState(() => _copyLabel = 'Copied');
    } catch (_) {
      if (!mounted) return;
      setState(() => _copyLabel = 'Select the link to copy');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.reference.title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          SelectableText(
            widget.reference.url,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF2563EB),
            ),
          ),
          TextButton.icon(
            onPressed: _copyLink,
            icon: Icon(
              _copyLabel == 'Copied' ? Icons.check : Icons.copy_outlined,
              size: 15,
            ),
            label: Text(_copyLabel),
          ),
        ],
      ),
    );
  }
}
