import 'package:flutter/material.dart';

class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isDisabled;
  final int bookedSlots;
  final VoidCallback? onTap;

  const DayCell({
    super.key,
    required this.date,
    required this.isSelected,
    required this.isDisabled,
    required this.bookedSlots,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;

    if (isDisabled) {
      color = Colors.red; // ✅ full
    } else if (bookedSlots > 0) {
      color = Colors.orange; // ✅ partial
    } else {
      color = Colors.green; // ✅ free
    }

    if (isSelected) {
      color = Colors.blue;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AspectRatio(
          aspectRatio: 1.2,
          child: Center(
            child: Text(
              "${date.day}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}