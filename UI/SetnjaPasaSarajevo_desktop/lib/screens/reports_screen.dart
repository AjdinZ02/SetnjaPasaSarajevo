import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/reservation.dart';
import '../providers/reservation_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _printReport(
    BuildContext context,
    List<Reservation> reservations, {
    required bool summary,
  }) async {
    final document = pw.Document();
    final rows = summary
        ? _summaryRows(reservations)
        : reservations
              .map(
                (r) => [
                  '${r.timeSlot?.date ?? '-'} ${r.timeSlot?.startTime ?? ''}',
                  '${r.firstName ?? ''} ${r.lastName ?? ''}'.trim(),
                  r.petName ?? '-',
                  r.status ?? '-',
                ],
              )
              .toList();
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(
            level: 0,
            text: summary ? 'Reservation status report' : 'Reservations report',
          ),
          pw.TableHelper.fromTextArray(
            headers: summary
                ? ['Status', 'Count']
                : ['Date', 'User', 'Pet', 'Status'],
            data: rows,
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  List<List<String>> _summaryRows(List<Reservation> reservations) {
    final counts = <String, int>{};
    for (final reservation in reservations) {
      final status = reservation.status ?? 'Unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts.entries
        .map((entry) => [entry.key, '${entry.value}'])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ReservationProvider();
    return FutureBuilder<List<Reservation>>(
      future: provider.getReservations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reservations = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PDF reports',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate printable operational reports from current reservation data.',
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('All reservations'),
                    onPressed: () =>
                        _printReport(context, reservations, summary: false),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('Status summary'),
                    onPressed: () =>
                        _printReport(context, reservations, summary: true),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
