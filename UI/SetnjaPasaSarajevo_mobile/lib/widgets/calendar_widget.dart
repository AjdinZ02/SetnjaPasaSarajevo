import 'package:flutter/material.dart';
import 'package:setnjapasasarajevo_mobile/models/reservation_day_model.dart';
import 'day_cell.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime? selectedDate;
  final List<ReservationDayModel> reservationDays;
  final Function(DateTime) onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarWidget({
    super.key,
    required this.displayMonth,
    required this.selectedDate,
    required this.reservationDays,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth =
        DateTime(displayMonth.year, displayMonth.month, 1);

    final daysInMonth =
        DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);

    final startWeekday = firstDayOfMonth.weekday;

    List<Widget> dayWidgets = [];

    for (int i = 1; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final dayDate =
          DateTime(displayMonth.year, displayMonth.month, i);

      final reservationDay = reservationDays.firstWhere(
        (d) =>
            d.date.year == dayDate.year &&
            d.date.month == dayDate.month &&
            d.date.day == dayDate.day,
        orElse: () =>
            ReservationDayModel(date: dayDate, bookedSlots: 0),
      );

      dayWidgets.add(
        DayCell(
          date: dayDate,
          bookedSlots: reservationDay.bookedSlots,
          isSelected: selectedDate != null &&
              dayDate.year == selectedDate!.year &&
              dayDate.month == selectedDate!.month &&
              dayDate.day == selectedDate!.day,
          isDisabled: reservationDay.isFullyBooked,
          onTap: () => onDaySelected(dayDate),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
            ),
            Text(
              "${displayMonth.month}/${displayMonth.year}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text("Mon"),
            Text("Tue"),
            Text("Wed"),
            Text("Thu"),
            Text("Fri"),
            Text("Sat"),
            Text("Sun"),
          ],
        ),

        const SizedBox(height: 8),

        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 7,
          childAspectRatio: 1.3,
          children: dayWidgets,
        ),
      ],
    );
  }
}