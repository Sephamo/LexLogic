import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/policy_service.dart';
import 'identity_verification_screen.dart';

class Policy {
  final int id;
  final String type;
  final String policyNumber;
  final String premium;
  final String status;
  final String renewalDate;
  final IconData icon;
  final Color color;

  Policy({
    required this.id,
    required this.type,
    required this.policyNumber,
    required this.premium,
    required this.status,
    required this.renewalDate,
    required this.icon,
    required this.color,
  });
}

class PolicyListScreen extends StatefulWidget {
  const PolicyListScreen({super.key});

  @override
  State<PolicyListScreen> createState() =>
      _PolicyListScreenState();
}

class _PolicyListScreenState extends State<PolicyListScreen> {
  final PolicyService _policyService = PolicyService();
  final AuthService _authService = AuthService();

  List<Policy> _policies = [];

  bool _isLoading = true;
  bool _isBiometricVerified = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.getProfile();

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
        });
        return;
      }

      final data = result.data;

      if (data is! Map<String, dynamic>) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Invalid profile data received from server.';
        });
        return;
      }

      final dynamic biometricValue =
          data['biometricVerified'];

      final bool biometricVerified =
          biometricValue == true ||
          biometricValue?.toString().toLowerCase() == 'true';

      if (!biometricVerified) {
        setState(() {
          _isBiometricVerified = false;
          _isLoading = false;
          _policies = [];
        });

        return;
      }

      setState(() {
        _isBiometricVerified = true;
      });

      await _loadPolicies();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to check verification status.';
      });
    }
  }

  Future<void> _openBiometricVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const IdentityVerificationScreen(),
      ),
    );

    if (!mounted) return;

    debugPrint(
      'POLICY SCREEN: IdentityVerificationScreen returned: $result',
    );

    if (result == true) {
      setState(() {
        _isBiometricVerified = true;
        _errorMessage = null;
      });

      await _loadPolicies();
    }
  }

  Future<void> _loadPolicies() async {
    if (!mounted) return;

    if (!_isBiometricVerified) {
      setState(() {
        _isLoading = false;
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await _policyService.getMyPolicies();

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
        });

        return;
      }

      final data = result.data;

      if (data is List) {
        final policies = data
            .whereType<Map<String, dynamic>>()
            .map(_policyFromJson)
            .toList();

        setState(() {
          _policies = policies;
          _isLoading = false;
        });

        return;
      }

      setState(() {
        _policies = [];
        _isLoading = false;
        _errorMessage =
            'Unexpected policy data received from the server.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load policies.';
      });
    }
  }

  Policy _policyFromJson(
    Map<String, dynamic> json,
  ) {
    final policyType =
        json['policyType']?.toString() ??
            'Unknown Policy';

    IconData icon = Icons.description_outlined;
    Color color = Colors.blue;

    final type = policyType.toLowerCase();

    if (type.contains('vehicle') ||
        type.contains('car')) {
      icon = Icons.directions_car_outlined;
      color = Colors.blue;
    } else if (type.contains('home')) {
      icon = Icons.home_outlined;
      color = Colors.teal;
    } else if (type.contains('life')) {
      icon = Icons.favorite_outline;
      color = Colors.pinkAccent;
    }

    return Policy(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(
                  json['id']?.toString() ?? '0',
                ) ??
              0,
      type: policyType,
      policyNumber:
          json['policyNumber']?.toString() ??
              'Unknown',
      premium: _formatPremium(
        json['premium'],
      ),
      status:
          json['status']?.toString() ??
              'UNKNOWN',
      renewalDate:
          _formatDate(json['endDate']),
      icon: icon,
      color: color,
    );
  }

  String _formatPremium(dynamic premium) {
    if (premium == null) {
      return 'R 0 / month';
    }

    final value =
        double.tryParse(premium.toString());

    if (value == null) {
      return 'R $premium / month';
    }

    return 'R ${value.toStringAsFixed(2)} / month';
  }

  String _formatDate(dynamic date) {
    if (date == null) {
      return 'N/A';
    }

    final parsedDate =
        DateTime.tryParse(date.toString());

    if (parsedDate == null) {
      return date.toString();
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsedDate.day.toString().padLeft(2, '0')} '
        '${months[parsedDate.month - 1]} '
        '${parsedDate.year}';
  }

  Widget _buildBiometricRequired() {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural,
                    size: 42,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Biometric Verification Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'You must complete biometric identity verification before you can view your insurance policies.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _openBiometricVerification,
                    icon: const Icon(
                      Icons.verified_user_outlined,
                    ),
                    label: const Text(
                      'Verify My Identity',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 42,
            ),

            const SizedBox(height: 12),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _checkBiometricStatus,
              child: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicies() {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'My Policies',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'View and manage all your insurance policies',
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            if (_policies.isEmpty)
              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'No policies found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'You currently have no policies available.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._policies.map(
                (policy) {
                  final isDueSoon =
                      policy.status
                              .toLowerCase() ==
                          'renewal due';

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 14,
                    ),
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
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
                              padding:
                                  const EdgeInsets.all(
                                10,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: policy.color
                                    .withOpacity(0.1),
                                shape:
                                    BoxShape.circle,
                              ),
                              child: Icon(
                                policy.icon,
                                color: policy.color,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    policy.type,
                                    style:
                                        const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Colors.black87,
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 2),

                                  Text(
                                    policy.policyNumber,
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: isDueSoon
                                    ? Colors.orange
                                        .withOpacity(
                                            0.12)
                                    : Colors.green
                                        .withOpacity(
                                            0.12),
                                borderRadius:
                                    BorderRadius
                                        .circular(20),
                              ),
                              child: Text(
                                policy.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: isDueSoon
                                      ? Colors.orange[800]
                                      : Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(
                          height: 24,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Premium',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.black45,
                                  ),
                                ),

                                const SizedBox(
                                    height: 2),

                                Text(
                                  policy.premium,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .end,
                              children: [
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.black45,
                                  ),
                                ),

                                const SizedBox(
                                    height: 2),

                                Text(
                                  policy.renewalDate,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF8F9FC),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: const Color(0xFFF8F9FC),
        child: _buildError(),
      );
    }

    if (!_isBiometricVerified) {
      return _buildBiometricRequired();
    }

    return _buildPolicies();
  }
}