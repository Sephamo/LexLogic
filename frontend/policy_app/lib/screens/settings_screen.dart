import 'package:flutter/material.dart';

import 'support_info_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _fraudAlerts = true;
  bool _policyReminders = false;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    return Container(
      color: const Color(0xFFF8F9FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              const Text('Manage your app preferences', style: TextStyle(fontSize: 13.5, color: Colors.black54)),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'Notifications',
                subtitle: 'Choose what you want to be notified about',
                children: [
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts on this device',
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  _ToggleRow(
                    icon: Icons.warning_amber_rounded,
                    title: 'Fraud Alerts',
                    subtitle: 'Immediate alerts for suspicious activity',
                    value: _fraudAlerts,
                    onChanged: (v) => setState(() => _fraudAlerts = v),
                  ),
                  _ToggleRow(
                    icon: Icons.event_outlined,
                    title: 'Policy Renewal Reminders',
                    subtitle: 'Reminders before your policies expire',
                    value: _policyReminders,
                    onChanged: (v) => setState(() => _policyReminders = v),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Support',
                subtitle: null,
                children: [
                  _LinkRow(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () => showSupportInfoDialog(
                      context,
                      page: SupportInfoPage.helpCenter,
                    ),
                  ),
                  _LinkRow(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => showSupportInfoDialog(
                      context,
                      page: SupportInfoPage.termsOfService,
                    ),
                  ),
                  _LinkRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => showSupportInfoDialog(
                      context,
                      page: SupportInfoPage.privacyPolicy,
                    ),
                  ),
                  _LinkRow(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    trailing: policyCheckAppVersion,
                    onTap: () => showSupportInfoDialog(
                      context,
                      page: SupportInfoPage.appVersion,
                    ),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Danger Zone', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 4),
                    const Text('These actions are permanent and cannot be undone', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showDeleteConfirmation(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Delete Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?'),
        content: const Text('This will permanently delete your account and all associated data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: call account deletion API
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
  Widget _buildSectionCard({required String title, String? subtitle, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.black87)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF3F4F8), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }
}
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final bool isLast;
  const _LinkRow({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF3F4F8), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(fontSize: 12.5, color: Colors.black45))
              else
                const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
