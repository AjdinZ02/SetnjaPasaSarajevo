import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/user_provider.dart';
import 'reservation_list_screen.dart';
import 'dashboard_screen.dart';
import 'user_list.dart';
import 'reports_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Reservations',
    'Users',
    'Reports',
  ];

  /// ✅ KLJUČNI FIX — više nema liste widgeta
  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen(key: ValueKey("dashboard"));
      case 1:
        return const ReservationListScreen(key: ValueKey("reservations"));
      case 2:
        return const UserList(key: ValueKey("users"));
      case 3:
        return const ReportsScreen(key: ValueKey("reports"));
      default:
        return const DashboardScreen();
    }
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Logged out'))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Scaffold(
        body: Row(
          children: [
            // ✅ SIDEBAR
            Container(
              width: 200,
              color: Colors.grey[900],
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  _buildMenuItem(Icons.dashboard, "Dashboard", 0),
                  _buildMenuItem(Icons.calendar_month, "Reservations", 1),
                  _buildMenuItem(Icons.people, "Users", 2),
                  _buildMenuItem(Icons.picture_as_pdf, "Reports", 3),

                  const Spacer(),

                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _logout(context),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ✅ CONTENT
            Expanded(
              child: Column(
                children: [
                  // ✅ TOP BAR
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _titles[_selectedIndex],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ✅ SCREEN CONTENT (sa animation + key fix)
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: selected ? Colors.green : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
