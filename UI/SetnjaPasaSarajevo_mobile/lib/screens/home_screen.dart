import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/reservation_provider.dart';
import 'package:setnjapasasarajevo_mobile/screens/reservation_create_screen.dart';
import 'package:setnjapasasarajevo_mobile/utils/app_theme.dart';
import 'package:setnjapasasarajevo_mobile/models/time_slot_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenData = AuthProvider.accessTokenDecoded;

    final firstName = tokenData?['FirstName'] ?? '';
    final lastName = tokenData?['LastName'] ?? '';
    final fullName = "$firstName $lastName".trim();

    final displayName = fullName.isNotEmpty
        ? fullName
        : tokenData?['Username'] ?? "Korisniče";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(displayName),

                  const SizedBox(height: AppTheme.spacing24),

                  _buildHeroCard(context),

                  const SizedBox(height: AppTheme.spacing24),

                  _buildUpcomingSection(context),

                  const SizedBox(height: AppTheme.spacing24),

                  _buildRecommendedSlotsSection(context),

                  const SizedBox(height: AppTheme.spacing24),

                  _buildGallery(),

                  const SizedBox(height: AppTheme.spacing24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ BACKGROUND (malo finiji blur)
  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset("assets/images/dog_bg.jpg", fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),
        ),
      ],
    );
  }

  // ✅ HEADER (bolji style)
  Widget _buildHeader(String username) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dobrodošli",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ✅ HERO CARD (premium card)
  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.shadowLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rezerviši šetnju za svog psa",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // ✅ preload da bude instant
                context
                    .read<ReservationProvider>()
                    .fetchReservationDaysForMonth(
                      DateTime.now().year,
                      DateTime.now().month,
                    );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReservationCreateScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: const Text(
                "Nova rezervacija",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPCOMING (clean + modern)
  Widget _buildUpcomingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vaša sljedeća rezervacija",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: AppTheme.spacing16),

        FutureBuilder<List<dynamic>>(
          future: context.read<ReservationProvider>().fetchReservations(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.7),
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Učitavanje...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final reservations = snapshot.data!;

            if (reservations.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.shadowMedium,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 40,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        "Nemate rezervacija",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final sortedReservations = List<dynamic>.from(reservations)
              ..sort(
                (a, b) =>
                    _reservationDateTime(a).compareTo(_reservationDateTime(b)),
              );
            final r = sortedReservations.first;

            final ts = r['timeSlot'];

            String dateText = "-";
            String timeText = "-";

            if (ts != null) {
              final dateObj = DateTime.tryParse(ts['date']);

              if (dateObj != null) {
                dateText = "${dateObj.day}.${dateObj.month}.${dateObj.year}";
              }

              final startTime = ts['startTime'];
              if (startTime != null) {
                timeText = startTime.toString().substring(0, 5);
              }
            }

            return Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.shadowMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.access_time_outlined,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📅 $dateText",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "🕒 $timeText",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.statusConfirmed,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXLarge,
                          ),
                        ),
                        child: Text(
                          r['isActive'] ? "Aktivna" : "U pripremi",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    '📍 ${r['address']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedSlotsSection(BuildContext context) {
    return FutureBuilder<List<TimeSlotModel>>(
      future: context.read<ReservationProvider>().fetchRecommendedTimeSlots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Preporučeni termini trenutno nisu dostupni.\n${snapshot.error}',
            style: const TextStyle(color: Colors.white70),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final recommended = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🔥 Preporučeni termini",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final slot = recommended[index];
                  final date =
                      "${slot.date.day}.${slot.date.month}.${slot.date.year}";
                  return Container(
                    width: 160,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.schedule, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          "📅 $date",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "🕒 ${slot.timeRange}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ GALERIJA (modern cards)
  Widget _buildGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Naše osoblje:",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _buildImageCard("assets/images/lejla.jpg")),
            const SizedBox(width: 10),
            Expanded(child: _buildImageCard("assets/images/mia.jpg")),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCard(String path) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.shadowLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Image.asset(path, height: 200, fit: BoxFit.cover),
      ),
    );
  }

  static DateTime _reservationDateTime(dynamic reservation) {
    final timeSlot = reservation['timeSlot'];
    if (timeSlot is! Map) return DateTime(9999);

    final date = DateTime.tryParse('${timeSlot['date']}');
    if (date == null) return DateTime(9999);

    final timeParts = '${timeSlot['startTime'] ?? '00:00:00'}'.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
