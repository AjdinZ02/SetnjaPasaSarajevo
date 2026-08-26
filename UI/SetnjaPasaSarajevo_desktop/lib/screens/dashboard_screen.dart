import 'package:flutter/material.dart';import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/reservation_provider.dart';
import '../models/reservation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

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
    final data =
        await context.read<ReservationProvider>().getReservations();

    setState(() {
      total = data.length;
      confirmed =
          data.where((x) => x.status == "Confirmed").length;
      pending =
          data.where((x) => x.status == "Pending").length;
      cancelled =
          data.where((x) => x.status == "Cancelled").length;

      recent = data.take(5).toList();
    });
  }

  double safeValue(int value) {
    return value == 0 ? 0.1 : value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfff5f6fa),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Dashboard",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // ✅ STAT CARDS (RESPONSIVE)
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: 250,
                    child: _card("Ukupno", total.toString(),
                        Colors.blue, Icons.list),
                  ),
                  SizedBox(
                    width: 250,
                    child: _card(
                        "Potvrđene",
                        confirmed.toString(),
                        Colors.green,
                        Icons.check),
                  ),
                  SizedBox(
                    width: 250,
                    child: _card(
                        "Na čekanju",
                        pending.toString(),
                        Colors.orange,
                        Icons.timer),
                  ),
                  SizedBox(
                    width: 250,
                    child: _card(
                        "Otkazane",
                        cancelled.toString(),
                        Colors.red,
                        Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Statistika statusa",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // ✅ PIE CHART (DONUT)
              SizedBox(
                height: 250,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: safeValue(confirmed),
                            color: Colors.green,
                            title: "Confirmed",
                          ),
                          PieChartSectionData(
                            value: safeValue(pending),
                            color: Colors.orange,
                            title: "Pending",
                          ),
                          PieChartSectionData(
                            value: safeValue(cancelled),
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
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // ✅ LISTA
              Card(
                elevation: 2,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = recent[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          (r.firstName != null &&
                                  r.firstName!.isNotEmpty)
                              ? r.firstName![0]
                              : "",
                        ),
                      ),
                      title: Text(
                          "${r.firstName ?? ""} ${r.lastName ?? ""}"),
                      subtitle: Text(r.petName ?? ""),
                      trailing: _statusChip(r.status),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String value, Color color, IconData icon) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status ?? "",
        style: TextStyle(color: color),
      ),
    );
  }
}
