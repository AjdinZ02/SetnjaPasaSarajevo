import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reservation.dart';
import '../providers/reservation_provider.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() =>
      _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {

  List<Reservation> data = [];
  bool loading = true;

  final List<String> statuses = [
    "Pending",
    "Confirmed",
    "Cancelled"
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result =
        await context.read<ReservationProvider>().getReservations();

    setState(() {
      data = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfff5f6fa),
      padding: const EdgeInsets.all(24),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Nema rezervacija"))
              : Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 40,
                      headingRowColor:
                          MaterialStateProperty.all(Colors.grey[100]),

                      columns: const [
                        DataColumn(label: Text("Korisnik")),
                        DataColumn(label: Text("Ljubimac")),
                        DataColumn(label: Text("Datum")),
                        DataColumn(label: Text("Vrijeme")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Akcije")),
                      ],

                      rows: data.map((r) {

                        final ts = r.timeSlot;

                        String date = "-";
                        String time = "-";

                        if (ts != null) {
                          final dt =
                              DateTime.tryParse(ts.date ?? "");
                          if (dt != null) {
                            date =
                                "${dt.day}.${dt.month}.${dt.year}";
                          }

                          if (ts.startTime != null) {
                            time =
                                ts.startTime!.substring(0, 5);
                          }
                        }

                        return DataRow(
                          cells: [

                            DataCell(Text(
                                "${r.firstName ?? ''} ${r.lastName ?? ''}")),

                            DataCell(Text(
                                "${r.petName ?? ''} (${r.petType ?? ''})")),

                            DataCell(Text(date)),
                            DataCell(Text(time)),

                            // ✅ STATUS DROPDOWN (FIX)
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _getColor(r.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  value: r.status ?? "Pending",
                                  underline: const SizedBox(),
                                  items: statuses.map((s) {
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Text(_getText(s)),
                                    );
                                  }).toList(),
                                  onChanged: (value) async {
                                    if (value == null) return;

                                    await context
                                        .read<ReservationProvider>()
                                        .updateStatus(r.id!, value);

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text("Status ažuriran")),
                                    );

                                    load();
                                  },
                                ),
                              ),
                            ),

                            // ✅ DELETE BUTTON
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () async {
                                  await context
                                      .read<ReservationProvider>()
                                      .deleteReservation(r.id!);

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text("Obrisano")),
                                  );

                                  load();
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }

  Color _getColor(String? status) {
    switch (status) {
      case "Confirmed":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      case "Pending":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getText(String status) {
    switch (status) {
      case "Confirmed":
        return "✅ Potvrđena";
      case "Cancelled":
        return "❌ Otkazana";
      case "Pending":
        return "⏳ Na čekanju";
      default:
        return status;
    }
  }
}