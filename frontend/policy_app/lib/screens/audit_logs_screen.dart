import 'package:flutter/material.dart';

import '../services/audit_service.dart';

class AuditLogItem {
  final String eventType;
  final String description;
  final String time;

  const AuditLogItem({
    required this.eventType,
    required this.description,
    required this.time,
  });
}

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);

  final AuditService _auditService = AuditService();

  bool _isLoading = true;
  String? _errorMessage;

  List<AuditLogItem> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _auditService.getMyLogs();

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.message;
      });
      return;
    }

    final data = result.data;

    debugPrint('MY AUDIT LOGS RESPONSE: $data');

    if (data is List) {
      final logs = data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            return AuditLogItem(
              eventType:
                  json['eventType']?.toString() ?? 'Unknown Event',
              description:
                  json['description']?.toString() ?? '',
              time: _formatAuditTime(json['createdAt']),
            );
          })
          .toList();

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } else {
      setState(() {
        _logs = [];
        _isLoading = false;
        _errorMessage =
            'Unexpected audit log data received from the server.';
      });
    }
  }

  String _formatAuditTime(dynamic createdAt) {
    if (createdAt == null) {
      return 'Unknown time';
    }

    final parsedDate = DateTime.tryParse(
      createdAt.toString(),
    );

    if (parsedDate == null) {
      return createdAt.toString();
    }

    final now = DateTime.now();
    final difference = now.difference(parsedDate);

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

  IconData _getEventIcon(String eventType) {
    final type = eventType.toLowerCase();

    if (type.contains('login')) {
      return Icons.login_rounded;
    }

    if (type.contains('logout')) {
      return Icons.logout_rounded;
    }

    if (type.contains('security')) {
      return Icons.security_outlined;
    }

    if (type.contains('fraud')) {
      return Icons.warning_amber_rounded;
    }

    if (type.contains('policy')) {
      return Icons.description_outlined;
    }

    if (type.contains('profile')) {
      return Icons.person_outline;
    }

    return Icons.history_rounded;
  }

  Color _getEventColor(String eventType) {
    final type = eventType.toLowerCase();

    if (type.contains('login')) {
      return Colors.green;
    }

    if (type.contains('logout')) {
      return Colors.orange;
    }

    if (type.contains('fraud')) {
      return Colors.redAccent;
    }

    if (type.contains('security')) {
      return Colors.orange;
    }

    if (type.contains('policy')) {
      return _gradientStart;
    }

    return _gradientEnd;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: RefreshIndicator(
        onRefresh: _loadAuditLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Audit Logs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Review activity and security events on your account',
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
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
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
                )
              else if (_logs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 42,
                        color: _gradientStart,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No audit activity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No security or account activity has been recorded yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _logs.map((log) {
                    final color = _getEventColor(log.eventType);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getEventIcon(log.eventType),
                              color: color,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.eventType,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  log.description,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  log.time,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}