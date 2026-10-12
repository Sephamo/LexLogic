import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';

import 'dashboard_screen.dart';
import 'policy_list_screen.dart';
import 'notifications_screen.dart';
import 'fraud_report_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  String _userName = 'User';
  String _userPhone = '';
  String _userInitials = 'U';

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      const DashboardScreen(),

      // Policies is still a normal screen, but its own
      // logic controls whether policies can be loaded.
      const PolicyListScreen(),

      const NotificationsScreen(),
      const FraudReportScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await _authService.getProfile();

      if (!mounted || !result.success || result.data == null) {
        return;
      }

      final data = result.data;

      if (data is Map<String, dynamic>) {
        final firstName = data['firstName']?.toString() ?? '';
        final lastName = data['lastName']?.toString() ?? '';
        final phone = data['phoneNumber']?.toString() ?? '';

        final fullName = '$firstName $lastName'.trim();

        String initials = 'U';

        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          initials =
              '${firstName[0]}${lastName[0]}'.toUpperCase();
        } else if (firstName.isNotEmpty) {
          initials = firstName[0].toUpperCase();
        }

        setState(() {
          _userName = fullName.isEmpty ? 'User' : fullName;
          _userPhone = phone;
          _userInitials = initials;
        });
      }
    } catch (e) {
      debugPrint(
        'MAIN NAVIGATION: profile loading failed: $e',
      );
    }
  }

  Future<void> _logout() async {
    await _storageService.deleteToken();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void _onNavigationItemTapped(int index) {
    debugPrint(
      'MAIN NAVIGATION: selected tab index = $index',
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationItemTapped,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),

          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Policies',
          ),

          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),

          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report),
            label: 'Reports',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
