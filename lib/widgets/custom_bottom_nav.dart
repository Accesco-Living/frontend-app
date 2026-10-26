import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/main_dashboard.dart';
import '../screens/unified_Cart.dart';
import '../screens/bookmarks_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNav({super.key, required this.currentIndex});

  static const Color accentColor = Color(0xFF8B0045);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home_outlined, 'Home', 0),
              _buildNavItem(context, Icons.shopping_cart_outlined, 'Cart', 1),
              _buildNavItem(context, Icons.favorite_border, 'Saved', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;
    return InkWell(
      onTap: isSelected ? null : () => _onItemTapped(context, index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? accentColor : Colors.black54, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainDashboard()),
        (route) => false,
      );
    } else if (index == 1) {
      if (currentIndex == 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UnifiedCartScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UnifiedCartScreen()));
      }
    } else if (index == 2) {
      if (currentIndex == 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BookmarksScreen()));
      }
    }
  }
}
