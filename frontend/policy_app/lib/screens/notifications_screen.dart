import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/fraud_service.dart';

class NotificationItem {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });
}

class FraudFlagItem {
  final String ruleType;
  final String description;
  final String riskLevel;
  final int riskScore;
  final String status;
  final String createdAt;

  FraudFlagItem({
    required this.ruleType,
    required this.description,
    required this.riskLevel,
    required this.riskScore,
    required this.status,
    required this.createdAt,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);

  final NotificationService _notificationService =
      NotificationService();

  final FraudService _fraudService = FraudService();

  bool _isLoading = true;
  String? _errorMessage;

  List<NotificationItem> _notifications = [];
  List<FraudFlagItem> _fraudFlags = [];

  String _riskLevel = 'LOW';
  int _riskScore = 0;
  int _openFlags = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  try {
    // Load notifications independently.
    final notificationResult =
        await _notificationService.getMyNotifications();

    // Load fraud risk status independently.
    final fraudStatusResult =
        await _fraudService.getMyStatus();

    // Load fraud flags independently.
    final fraudFlagsResult =
        await _fraudService.getMyFlags();

    if (!mounted) return;

    // ----------------------------------------------------------
    // NOTIFICATIONS
    // ----------------------------------------------------------

    if (notificationResult.success) {
      _mapNotifications(notificationResult.data);
    }

    // ----------------------------------------------------------
    // FRAUD STATUS
    // ----------------------------------------------------------

    if (fraudStatusResult.success) {
      _mapFraudStatus(fraudStatusResult.data);
    }

    // ----------------------------------------------------------
    // FRAUD FLAGS
    // ----------------------------------------------------------

    if (fraudFlagsResult.success) {
      _mapFraudFlags(fraudFlagsResult.data);
    }

    // ----------------------------------------------------------
    // ERROR HANDLING
    // ----------------------------------------------------------

    final errors = <String>[];

    if (!notificationResult.success) {
      errors.add('Notifications: ${notificationResult.message}');
    }

    if (!fraudStatusResult.success) {
      errors.add('Fraud status: ${fraudStatusResult.message}');
    }

    if (!fraudFlagsResult.success) {
      errors.add('Fraud flags: ${fraudFlagsResult.message}');
    }

    setState(() {
      _isLoading = false;

      if (errors.isNotEmpty) {
        _errorMessage = errors.join('\n');
      } else {
        _errorMessage = null;
      }
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage =
          'Unable to load fraud alerts and notifications.';
    });

    debugPrint(
      'NOTIFICATIONS/FRAUD ERROR: $e',
    );
  }
}

  void _mapNotifications(dynamic data) {
    if (data is! List) {
      _notifications = [];
      return;
    }

    _notifications = data
        .whereType<Map<String, dynamic>>()
        .map((json) {
      final title =
          json['title']?.toString() ?? 'Notification';

      final type = title.toLowerCase();

      IconData icon =
          Icons.notifications_outlined;

      Color color = _gradientStart;

      if (type.contains('fraud')) {
        icon = Icons.warning_amber_rounded;
        color = Colors.redAccent;
      } else if (type.contains('policy')) {
        icon = Icons.description_outlined;
        color = Colors.blue;
      } else if (type.contains('security') ||
          type.contains('login')) {
        icon = Icons.security_outlined;
        color = Colors.orange;
      }

      return NotificationItem(
        icon: icon,
        color: color,
        title: title,
        message:
            json['message']?.toString() ?? '',
        time: _formatTime(json['createdAt']),
        isRead: json['read'] == true,
      );
    }).toList();
  }

  void _mapFraudStatus(dynamic data) {
    if (data is! Map<String, dynamic>) {
      _riskLevel = 'UNKNOWN';
      _riskScore = 0;
      _openFlags = 0;
      return;
    }

    _riskLevel =
        data['riskLevel']?.toString() ?? 'UNKNOWN';

    _riskScore = _parseInt(data['riskScore']);

    _openFlags = _parseInt(data['openFlags']);
  }

  void _mapFraudFlags(dynamic data) {
    if (data is! List) {
      _fraudFlags = [];
      return;
    }

    _fraudFlags = data
        .whereType<Map<String, dynamic>>()
        .map((json) {
      return FraudFlagItem(
        ruleType:
            json['ruleType']?.toString() ??
                'Unknown Rule',
        description:
            json['description']?.toString() ?? '',
        riskLevel:
            json['riskLevel']?.toString() ??
                'UNKNOWN',
        riskScore:
            _parseInt(json['riskScore']),
        status:
            json['status']?.toString() ??
                'UNKNOWN',
        createdAt:
            _formatTime(json['createdAt']),
      );
    }).toList();
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) {
      return 'Unknown time';
    }

    final parsedDate =
        DateTime.tryParse(createdAt.toString());

    if (parsedDate == null) {
      return createdAt.toString();
    }

    final now = DateTime.now();

    final difference =
        now.difference(parsedDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${parsedDate.day.toString().padLeft(2, '0')}/'
        '${parsedDate.month.toString().padLeft(2, '0')}/'
        '${parsedDate.year}';
  }

  Color _riskColor() {
    switch (_riskLevel.toUpperCase()) {
      case 'HIGH':
        return Colors.redAccent;

      case 'MEDIUM':
        return Colors.orange;

      case 'LOW':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  IconData _riskIcon() {
    switch (_riskLevel.toUpperCase()) {
      case 'HIGH':
        return Icons.warning_amber_rounded;

      case 'MEDIUM':
        return Icons.info_outline;

      case 'LOW':
        return Icons.verified_outlined;

      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Fraud Alerts & Notifications',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Stay updated on your account and policy activity',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                _buildError()
              else
                _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.15),
        ),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildRiskCard(),

        const SizedBox(height: 20),

        if (_fraudFlags.isNotEmpty)
          _buildFraudFlags(),

        if (_fraudFlags.isNotEmpty)
          const SizedBox(height: 20),

        _buildNotifications(),
      ],
    );
  }

  Widget _buildRiskCard() {
    final color = _riskColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _riskIcon(),
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  'Fraud Risk Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              Text(
                _riskLevel,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildRiskStat(
                  'Risk Score',
                  '$_riskScore',
                ),
              ),

              Expanded(
                child: _buildRiskStat(
                  'Open Flags',
                  '$_openFlags',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskStat(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildFraudFlags() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Fraud Flags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(height: 10),

        ..._fraudFlags.map(
          (flag) => _buildFraudFlagCard(flag),
        ),
      ],
    );
  }

  Widget _buildFraudFlagCard(
    FraudFlagItem flag,
  ) {
    final color =
        flag.riskLevel.toUpperCase() == 'HIGH'
            ? Colors.redAccent
            : flag.riskLevel
                        .toUpperCase() ==
                    'MEDIUM'
                ? Colors.orange
                : Colors.green;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: color,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  flag.ruleType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  flag.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      flag.riskLevel,
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      'Score: ${flag.riskScore}',
                      style:
                          const TextStyle(
                        fontSize: 11.5,
                        color:
                            Colors.black45,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      flag.status,
                      style:
                          const TextStyle(
                        fontSize: 11.5,
                        color:
                            Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (_notifications.isEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Text(
              'No notifications available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          )
        else
          ..._notifications.map(
            (n) => _buildNotificationCard(n),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(
    NotificationItem n,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: n.isRead
            ? Colors.white
            : const Color(0xFFEFF4FF),
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  n.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              n.icon,
              color: n.color,
              size: 20,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.black87,
                        ),
                      ),
                    ),

                    if (!n.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            const BoxDecoration(
                          color:
                              Colors.redAccent,
                          shape:
                              BoxShape.circle,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  n.message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  n.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black38,
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