import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; 
import '../providers/reservation_provider.dart';
import '../models/reservation.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int total = 0;
  int confirmed = 0;
  int pending = 0;
  int cancelled = 0;

  List<Reservation> recent = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await context.read<ReservationProvider>().getReservations();

    total = data.length;
    confirmed = data.where((x) => x.status == "Confirmed").length;
    pending = data.where((x) => x.status == "Pending").length;
    cancelled = data.where((x) => x.status == "Cancelled").length;

    recent = data.take(5).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfff5f6fa),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "Admin Dashboard",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // ✅ CARDS
          Row(
            children: [
              _card("Ukupno", total.toString(), Colors.blue, Icons.list),
              const SizedBox(width: 20),
              _card("Potvrđene", confirmed.toString(), Colors.green, Icons.check),
              const SizedBox(width: 20),
              _card("Na čekanju", pending.toString(), Colors.orange, Icons.timer),
              const SizedBox(width: 20),
              _card("Otkazane", cancelled.toString(), Colors.red, Icons.close),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            "Statistika statusa",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          // ✅ CHART
          SizedBox(
            height: 250,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: confirmed.toDouble(),
                        color: Colors.green,
                        title: "Confirmed",
                      ),
                      PieChartSectionData(
                        value: pending.toDouble(),
                        color: Colors.orange,
                        title: "Pending",
                      ),
                      PieChartSectionData(
                        value: cancelled.toDouble(),
                        color: Colors.red,
                        title: "Cancelled",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Zadnje rezervacije",
            style: TextStyle(fontSize: 20),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: recent.map((r) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (r.firstName != null && r.firstName!.isNotEmpty)
                          ? r.firstName![0]
                          : "",
                    ),
                  ),
                  title: Text("${r.firstName ?? ""} ${r.lastName ?? ""}"),
                  subtitle: Text(r.petName ?? ""),
                  trailing: _statusChip(r.status),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                Text(value,
                    style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String? status) {
    Color color;

    switch (status) {
      case "Confirmed":
        color = Colors.green;
        break;
      case "Cancelled":
        color = Colors.red;
        break;
      case "Pending":
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status ?? "", style: TextStyle(color: color)),
    );
  }
}

