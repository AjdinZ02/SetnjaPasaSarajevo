import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setnjapasasarajevo_mobile/models/pet.dart';
import 'package:setnjapasasarajevo_mobile/models/reservation_day_model.dart';
import 'package:setnjapasasarajevo_mobile/models/time_slot_model.dart';
import 'package:setnjapasasarajevo_mobile/models/user.dart';
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/pet_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/reservation_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/user_provider.dart';
import 'package:setnjapasasarajevo_mobile/widgets/calendar_widget.dart';
import 'package:setnjapasasarajevo_mobile/widgets/time_slot_widget.dart';

class ReservationCreateScreen extends StatefulWidget {
  const ReservationCreateScreen({super.key});

  @override
  State<ReservationCreateScreen> createState() =>
      _ReservationCreateScreenState();
}

class _ReservationCreateScreenState extends State<ReservationCreateScreen> {

  final _scrollController = ScrollController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  TimeSlotModel? _selectedSlot; // ✅ FIXED: No string slots

  List<ReservationDayModel> _reservationDays = [];
  List<TimeSlotModel> _timeSlots = [];
  List<Pet> _pets = [];

  int? _selectedPetId;
  User? _user;

  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPets();
    _loadCalendar(month: _currentMonth);
  }

  // ✅ LOAD USER
  Future<void> _loadUser() async {
    try {
      int userId = int.tryParse(
        AuthProvider.accessTokenDecoded?['Id']?.toString() ?? ''
      ) ?? 0;

      final user = await context.read<UserProvider>().getById(userId);

      if (!mounted) return;

      setState(() {
        _user = user;
        _addressController.text = user.address ?? "";
      });
    } catch (e) {
      print("Error loading user: $e");
    }
  }

  // ✅ LOAD PETS
  Future<void> _loadPets() async {
    try {
      final pets = await context.read<PetProvider>().getMyPets();

      if (!mounted) return;

      setState(() {
        _pets = pets;
        if (_pets.isNotEmpty) {
          _selectedPetId = _pets.first.id;
        }
      });
    } catch (e) {
      print("Error loading pets: $e");
    }
  }

  // ✅ LOAD CALENDAR
  Future<void> _loadCalendar({required DateTime month}) async {
    try {
      final provider = context.read<ReservationProvider>();
      final days = await provider.fetchReservationDaysForMonth(
        month.year,
        month.month,
      );

      if (!mounted) return;

      setState(() {
        _reservationDays = days;
        _selectedDate = days.isNotEmpty ? days.first.date : null;
        
        // Reset slot selection when changing month
        _selectedSlot = null;
      });

      if (_selectedDate != null) {
        _loadTimeSlots(_selectedDate!);
      }
    } catch (e) {
      print("Error loading calendar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Greška pri učitavanju kalendara: $e")),
      );
    }
  }

  // ✅ LOAD TIME SLOTS
  Future<void> _loadTimeSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);

    try {
      final provider = context.read<ReservationProvider>();
      final slots = await provider.fetchTimeSlotsForDate(date);

      if (!mounted) return;

      setState(() {
        _timeSlots = slots;
        _selectedSlot = null; // Reset selection on new date
      });
    } catch (e) {
      print("Error loading time slots: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Greška pri učitavanju vremena: $e")),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoadingSlots = false);
    }
  }

  // ✅ DAY SELECTED
  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null; // Reset slot when changing date
    });
    _loadTimeSlots(date);
  }

  // ✅ SUBMIT RESERVATION
  Future<void> _submit() async {
    if (_selectedDate == null ||
        _selectedSlot == null ||
        _selectedPetId == null ||
        _user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Molimo odaberite sve parametre")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedPet = _pets.firstWhere((p) => p.id == _selectedPetId);

      // ✅ CORRECT PAYLOAD WITH TimeSlotId
      final payload = {
        "userId": _user!.id,
        "petId": _selectedPetId,
        "timeSlotId": _selectedSlot!.id, // ✅ Using TimeSlot ID from backend
        "petName": selectedPet.name,
        "petType": selectedPet.type,
        "notes": _notesController.text,
      };

      print("📤 PAYLOAD: $payload");

      await context.read<ReservationProvider>().createReservation(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Rezervacija uspješna!"),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form and reload
      setState(() {
        _selectedSlot = null;
        _notesController.clear();
        _currentMonth = DateTime.now();
      });

      _loadCalendar(month: _currentMonth);

    } catch (e) {
      print("Error submitting: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Greška: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova rezervacija')),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [

          // ✅ STEP 1: SELECT DATE
          const Text(
            "Korak 1: Odaberite datum",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                )
              ],
            ),
            child: CalendarWidget(
              displayMonth: _currentMonth,
              selectedDate: _selectedDate,
              reservationDays: _reservationDays,
              onDaySelected: _onDaySelected,
              onPreviousMonth: () {
                final newMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
                setState(() {
                  _currentMonth = newMonth;
  _reservationDays = [];
  _timeSlots = []; // <-- DODAJ
  _selectedDate = null;
  _selectedSlot = null;
});
                _loadCalendar(month: newMonth);
              },
              onNextMonth: () {
                final newMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                );
                setState(() {
                  _currentMonth = newMonth;
                  _reservationDays = [];
                  _timeSlots = []; // <-- DODAJ
                  _selectedDate = null;
                  _selectedSlot = null;
                });
                _loadCalendar(month: newMonth);
              },
            ),
          ),

          const SizedBox(height: 20),

          // ✅ STEP 2: SELECT TIME SLOT
          const Text(
            "Korak 2: Odaberite vrijeme",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isLoadingSlots
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _timeSlots.isEmpty
                    ? const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            "Nema dostupnih vremena za odabrani datum",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : (_selectedDate == null)
    ? const SizedBox(
        height: 80,
        child: Center(
          child: Text("Učitavanje dostupnih termina..."),
        ),
      )
    : Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _timeSlots.map((slot) {
          final now = DateTime.now();

          final slotDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            int.parse(slot.startTime.split(':')[0]),
            int.parse(slot.startTime.split(':')[1]),
          );

          final isPast = slotDateTime.isBefore(now);
          final isBooked = slot.isBooked ?? false;

          return Opacity(
            opacity: isPast ? 0.5 : 1.0,
            child: TimeSlotWidget(
              slot: slot,
              isSelected: _selectedSlot?.id == slot.id,
              onTap: (isPast || isBooked)
                  ? null
                  : () {
                      setState(() {
                        _selectedSlot = slot;
                      });
                    },
            ),
          );
        }).toList(),
      )
          ),

          const SizedBox(height: 20),

          // ✅ LEGEND
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem("Dostupno", Colors.green.shade600),
                _legendItem("Odabrano", Colors.green.shade800),
                _legendItem("Zauzeto", Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ✅ STEP 3: SHOW FORM ONLY AFTER SLOT SELECTED
          if (_selectedSlot != null) ...[
            const Text(
              "Korak 3: Popunite podatke",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [

                  // Selected slot summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "📅 ${_selectedDate?.toString().split(' ')[0]} | ⏰ ${_selectedSlot!.timeRange}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pet dropdown
                  DropdownButtonFormField<int>(
                    value: _selectedPetId,
                    items: _pets.map((pet) {
                      return DropdownMenuItem(
                        value: pet.id,
                        child: Text(pet.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPetId = value);
                    },
                    decoration: const InputDecoration(
                      labelText: "🐕 Pas",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Address field
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "📍 Adresa",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes field
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "📝 Napomena (opciono)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              "✅ Rezerviši",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper widget for legend
  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}