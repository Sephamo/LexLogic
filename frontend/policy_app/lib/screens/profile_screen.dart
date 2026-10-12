import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'audit_logs_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic> _profile = {};
  bool _isLoading = false;
  String? _errorMessage;

  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _profile = {};
    });

    try {
      // Use the same authenticated profile request as DashboardScreen.
      final result = await _authService.getProfile();
      if (!mounted) return;
      if (!result.success || result.data is! Map) {
        throw StateError('Profile response unavailable');
      }
      final profile = Map<String, dynamic>.from(result.data as Map);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your profile. Please try again.';
      });
    }
  }

  String? _readText(List<String> keys) {
    for (final key in keys) {
      final value = _profile[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  bool? _readBoolean(List<String> keys) {
    for (final key in keys) {
      final value = _profile[key];
      if (value is bool) return value;
      switch (value?.toString().trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return null;
  }

  String get _userName {
    // These fields are confirmed by the supplied dashboard code.
    final firstName = _readText(['firstName']) ?? '';
    final lastName = _readText(['lastName']) ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'User' : fullName;
  }

  String get _initials {
    final parts = _userName.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  // Optional response keys: adjust these if your backend uses other names.
  String get _idNumber {
    final value = _readText([
      'idNumber',
      'saIdNumber',
      'nationalIdNumber',
      'id_number',
      'sa_id_number',
    ]);
    if (value == null) return 'Not provided';
    if (RegExp(r'[•*]').hasMatch(value)) return value;
    // Preserve the original masking: reveal only the last 3 digits.
    final hiddenLength = value.length > 3 ? value.length - 3 : value.length;
    final hidden = List.filled(hiddenLength, '•').join();
    return value.length > 3 ? '$hidden${value.substring(hiddenLength)}' : hidden;
  }

  String get _phoneNumber =>
      _readText(['phoneNumber', 'phone', 'mobileNumber', 'phone_number']) ??
      'Not provided';

  String get _memberSince {
    final value = _readText([
      'createdAt',
      'memberSince',
      'registeredAt',
      'created_at',
    ]);
    if (value == null) return 'Not provided';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final localDate = date.toLocal();
    return '${_months[localDate.month - 1]} ${localDate.year}';
  }

  bool? get _twoFactorEnabled =>
      _readBoolean(['twoFactorEnabled', 'isTwoFactorEnabled', 'two_factor_enabled']);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _loadProfile,
                    tooltip: 'Refresh profile',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your account information',
                style: TextStyle(fontSize: 13.5, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildProfileHeaderCard(context),
                const SizedBox(height: 16),

                _buildPersonalDetailsCard(),
                const SizedBox(height: 16),
                _buildSecurityCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 420;

    final avatar = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: isNarrow
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          _userName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: isNarrow ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    final editButton = OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
      label: const Text('Edit', style: TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_gradientStart, _gradientEnd]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: isNarrow
          ? Column(
              children: [
                avatar,
                const SizedBox(height: 14),
                info,
                const SizedBox(height: 16),
                editButton,
              ],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: 18),
                Expanded(child: info),
                editButton,
              ],
            ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: _userName,
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'SA ID Number',
            value: _idNumber,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: _phoneNumber,
          ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: _memberSince,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your account security',
            style: TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          const SizedBox(height: 16),

          _SettingsTile(
            icon: Icons.smartphone_outlined,
            title: 'Two-Factor Authentication',
            subtitle: _twoFactorEnabled == true
                ? 'Two-factor authentication is enabled'
                : _twoFactorEnabled == false
                    ? 'Two-factor authentication is disabled'
                    : 'Two-factor status unavailable',
            onTap: () {},
            trailing: _buildTwoFactorChip(),
          ),

          _SettingsTile(
            icon: Icons.history_outlined,
            title: 'Audit Logs',
            subtitle: 'View your account activity and security events',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
              );
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTwoFactorChip() {
    final enabled = _twoFactorEnabled;
    final color = enabled == true ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        enabled == true
            ? 'Enabled'
            : enabled == false
                ? 'Disabled'
                : 'Unknown',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black45),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
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
          padding: EdgeInsets.symmetric(
            vertical: 12,
          ).copyWith(bottom: isLast ? 0 : 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.black26,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
