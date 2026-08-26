import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/reservation_provider.dart';
import 'package:setnjapasasarajevo_mobile/utils/reservation_helpers.dart';

class ReservationsListScreen extends StatefulWidget {
  const ReservationsListScreen({super.key});

  @override
  State<ReservationsListScreen> createState() =>
      _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  List<dynamic>? _reservations;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final provider = context.read<ReservationProvider>();

      final isAdmin =
          AuthProvider.accessTokenDecoded?['role'] == "Admin";

      final list = isAdmin
          ? await provider.getAllReservations()
          : await provider.getMyReservations();

      if (!mounted) return;

      setState(() {
        _reservations = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Confirmed":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      case "Cancelled":
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    await context.read<ReservationProvider>().updateStatus(id, status);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Status ažuriran")),
    );

    _load();
  }

  Future<void> _deleteReservation(int id, int index) async {
    await context.read<ReservationProvider>().deleteReservation(id);

    setState(() {
      _reservations!.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Rezervacija otkazana")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        AuthProvider.accessTokenDecoded?['role'] == "Admin";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje rezervacije'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reservations == null || _reservations!.isEmpty
                ? const Center(child: Text('Nemate rezervacija'))
                : ListView.separated(
                    itemCount: _reservations!.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r =
                          _reservations![index] as Map<String, dynamic>;

                      final id = r['id'];
                      final firstName = r['firstName'] ?? '';
                      final lastName = r['lastName'] ?? '';
                      final petName = r['petName'] ?? '';
                      final status =
                          (r['status'] ?? "Pending").toString().trim();

                      final date = formatReservationDate(r);
                      final time = formatReservationTime(r);

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.pets, size: 32),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$firstName $lastName",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text("Pas: $petName"),
                                        Text("Datum: $date"),
                                        Text("Vrijeme: $time"),
                                      ],
                                    ),
                                  ),

                                  Column(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5),
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(status),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),

                                      if (isAdmin)
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == "confirm") {
                                              _updateStatus(
                                                  id, "Confirmed");
                                            } else if (value ==
                                                "reject") {
                                              _updateStatus(
                                                  id, "Rejected");
                                            } else if (value ==
                                                "delete") {
                                              _deleteReservation(
                                                  id, index);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                                value: "confirm",
                                                child:
                                                    Text("✅ Potvrdi")),
                                            PopupMenuItem(
                                                value: "reject",
                                                child:
                                                    Text("❌ Odbij")),
                                            PopupMenuItem(
                                                value: "delete",
                                                child:
                                                    Text("🗑 Izbriši")),
                                          ],
                                        ),
                                    ],
                                  )
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// ✅ CANCEL BUTTON
                              if (!isAdmin &&
                                  status.toLowerCase() != "cancelled")
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12),
                                    ),
                                    onPressed: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (_) =>
                                            AlertDialog(
                                          title: const Text(
                                              "Otkaži rezervaciju"),
                                          content: const Text(
                                              "Da li ste sigurni?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context,
                                                      false),
                                              child:
                                                  const Text("Ne"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context,
                                                      true),
                                              child:
                                                  const Text("Da"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        _deleteReservation(
                                            id, index);
                                      }
                                    },
                                    child: const Text(
                                      "Otkaži",
                                      style: TextStyle(
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
