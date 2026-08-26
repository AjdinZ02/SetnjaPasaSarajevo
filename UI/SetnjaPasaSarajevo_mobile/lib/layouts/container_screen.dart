import 'package:flutter/material.dart';
import 'package:setnjapasasarajevo_mobile/screens/reservations_list_screen.dart';
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/screens/admin_reservations_screen.dart';
// import 'package:setnjapasasarajevo_mobile/screens/my_reservations_screen.dart';
import 'package:setnjapasasarajevo_mobile/screens/profile_screen.dart';
import 'package:setnjapasasarajevo_mobile/screens/home_screen.dart';
import 'package:setnjapasasarajevo_mobile/screens/wallet_screen.dart';

class ContainerScreen extends StatefulWidget {
  const ContainerScreen({super.key});

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ✅ Handle back button: return to Home instead of popping to LoginScreen
  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      // If not on home, go back to home instead of popping navigator
      setState(() {
        _selectedIndex = 0;
      });
      return false; // Don't pop
    }
    // If already on home, allow back navigation (will pop to previous screen if any)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[HomeScreen()];
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Početna')
    ];

    if (AuthProvider.isAdmin) {
      pages.add(const AdminReservationsScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Rezervacije'));
    } else {
      pages.add(const ReservationsListScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Rezervacije'));
    }

    if (!AuthProvider.isAdmin) {
      pages.add(const WalletScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Krediti'));
    }

    pages.add(ProfileScreen());
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFE53935),
          unselectedItemColor: const Color(0xFF5F6368),
          selectedIconTheme: const IconThemeData(color: Color(0xFFE53935)),
          unselectedIconTheme: const IconThemeData(color: Color(0xFF5F6368)),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: items,
        ),
      ),
    );
  }
}
