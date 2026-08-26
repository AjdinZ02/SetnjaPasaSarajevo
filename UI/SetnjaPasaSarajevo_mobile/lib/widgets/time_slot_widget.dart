import 'package:flutter/material.dart';
import 'package:setnjapasasarajevo_mobile/models/time_slot_model.dart';

class TimeSlotWidget extends StatelessWidget {
  final TimeSlotModel slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const TimeSlotWidget({
    super.key,
    required this.slot,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color textColor = Colors.white;
    bool isDisabled = false;

    if (slot.isBooked) {
      background = Colors.red;
      textColor = Colors.white;
      isDisabled = true;
    } else if (isSelected) {
      background = Colors.green.shade800;
    } else {
      background = Colors.green.shade600;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          width: 90,
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            slot.display,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}