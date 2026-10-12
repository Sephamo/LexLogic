import 'package:flutter/material.dart';

import '../services/fraud_service.dart';
import '../services/policy_service.dart';

class _PolicyOption {
  final int id;
  final String displayName;

  const _PolicyOption({
    required this.id,
    required this.displayName,
  });
}

class FraudReportScreen extends StatefulWidget {
  const FraudReportScreen({super.key});

  @override
  State<FraudReportScreen> createState() => _FraudReportScreenState();
}

class _FraudReportScreenState extends State<FraudReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final FraudService _fraudService = FraudService();
  final PolicyService _policyService = PolicyService();

  final _descriptionController = TextEditingController();

  int? _selectedPolicyId;
  String? _selectedFraudType;

  bool _isSubmitting = false;
  bool _isLoadingPolicies = true;

  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);

  List<_PolicyOption> _policies = [];

  final List<String> _fraudTypes = [
    'False Claim',
    'Identity Theft',
    'Premium Diversion',
    'Staged Incident',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    setState(() {
      _isLoadingPolicies = true;
    });

    final result = await _policyService.getMyPolicies();

    if (!mounted) return;

    if (!result.success) {
      debugPrint(
        'FRAUD SCREEN POLICIES ERROR: ${result.message}',
      );

      setState(() {
        _policies = [];
        _isLoadingPolicies = false;
      });

      return;
    }

    final data = result.data;

    debugPrint(
      'FRAUD SCREEN POLICIES RESPONSE: $data',
    );

    if (data is List) {
      final policies = data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            final id = json['id'] is int
                ? json['id'] as int
                : int.tryParse(
                      json['id']?.toString() ?? '',
                    ) ??
                    0;

            final policyNumber =
                json['policyNumber']?.toString() ?? 'Unknown';

            final policyType =
                json['policyType']?.toString() ?? 'Unknown Policy';

            return _PolicyOption(
              id: id,
              displayName:
                  '$policyNumber — $policyType',
            );
          })
          .where((policy) => policy.id != 0)
          .toList();

      setState(() {
        _policies = policies;
        _isLoadingPolicies = false;
      });
    } else {
      setState(() {
        _policies = [];
        _isLoadingPolicies = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe what happened';
    }

    if (value.trim().length < 20) {
      return 'Please provide more detail (min 20 characters)';
    }

    return null;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPolicyId == null ||
        _selectedFraudType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a policy and fraud type',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final reason =
        '${_selectedFraudType!}: '
        '${_descriptionController.text.trim()}';

    final result = await _fraudService.submitFraudReport(
      reportData: {
        'policyId': _selectedPolicyId,
        'reason': reason,
      },
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Report Submitted'),
        content: const Text(
          'Your fraud report has been received. '
          'Our team will review it and follow up via email.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              _formKey.currentState!.reset();
              _descriptionController.clear();

              setState(() {
                _selectedPolicyId = null;
                _selectedFraudType = null;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 640,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Report Fraud',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Report a policy you don\'t recognize or suspect to be fraudulent',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[800],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'All reports are confidential and reviewed by our fraud investigation team.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Related Policy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<int>(
                  value: _selectedPolicyId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  hint: Text(
                    _isLoadingPolicies
                        ? 'Loading policies...'
                        : _policies.isEmpty
                            ? 'No policies available'
                            : 'Select a policy',
                  ),
                  items: _policies
                      .map(
                        (policy) =>
                            DropdownMenuItem<int>(
                          value: policy.id,
                          child: Text(
                            policy.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged:
                      _isLoadingPolicies ||
                              _policies.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _selectedPolicyId =
                                    value;
                              });
                            },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Type of Fraud',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedFraudType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  hint: const Text(
                    'Select fraud type',
                  ),
                  items: _fraudTypes
                      .map(
                        (type) =>
                            DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFraudType = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _descriptionController,
                  validator: _validateDescription,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Describe what happened in as much detail as possible...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: file picker for evidence attachments
                  },
                  icon: const Icon(
                    Icons.attach_file,
                    size: 18,
                  ),
                  label: const Text(
                    'Attach Evidence (optional)',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _gradientStart,
                        _gradientEnd,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(12),
                      onTap: _isSubmitting
                          ? null
                          : _submitReport,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Report',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
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
}