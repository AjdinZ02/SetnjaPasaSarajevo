import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/reservation_provider.dart';
import 'package:setnjapasasarajevo_mobile/utils/reservation_helpers.dart';
import 'package:setnjapasasarajevo_mobile/utils/app_theme.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  List<dynamic>? _reservations;
  bool _loading = true;

  // ✅ FILTER & SEARCH
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Cancelled',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final list =
          await context.read<ReservationProvider>().getAllReservations();

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

  // use utils/reservation_helpers.dart for date formatting

  Color _getStatusColor(String status) {
    return AppTheme.getStatusColor(status);
  }

  Future<void> _updateStatus(int id, String status) async {
  try {
    await context.read<ReservationProvider>().updateStatus(id, status);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Status ažuriran")),
    );

    _load();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Greška: $e")),
    );
  }
}

// ✅ FILTER LOGIC
List<dynamic> _getFilteredReservations() {
  if (_reservations == null) return [];

  return _reservations!.where((r) {
    // Status filter
    if (_selectedStatus != 'All') {
      final status = r['status'] ?? 'Pending';
      if (status != _selectedStatus) return false;
    }

    // Search filter (by first name + last name)
    if (_searchQuery.isNotEmpty) {
      final firstName = (r['firstName'] ?? '').toLowerCase();
      final lastName = (r['lastName'] ?? '').toLowerCase();
      final fullName = '$firstName $lastName';
      final query = _searchQuery.toLowerCase();
      if (!fullName.contains(query)) return false;
    }

    return true;
  }).toList();
}

// ✅ GROUP BY DATE
Map<String, List<dynamic>> _groupReservationsByDate(
    List<dynamic> reservations) {
  final grouped = <String, List<dynamic>>{};

  for (final r in reservations) {
    final dateStr = formatReservationDate(r);
    if (dateStr != '-') {
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(r);
    }
  }

  // Sort by date
  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) {
      try {
        final aParts = a.split('.');
        final bParts = b.split('.');
        final aDate = DateTime(int.parse(aParts[2]), int.parse(aParts[1]),
            int.parse(aParts[0]));
        final bDate = DateTime(int.parse(bParts[2]), int.parse(bParts[1]),
            int.parse(bParts[0]));
        return aDate.compareTo(bDate);
      } catch (_) {
        return 0;
      }
    });

  final sortedGrouped = <String, List<dynamic>>{};
  for (final key in sortedKeys) {
    sortedGrouped[key] = grouped[key]!;
  }

  return sortedGrouped;
}


  @override
  Widget build(BuildContext context) {
    final filteredReservations = _getFilteredReservations();
    final groupedByDate = _groupReservationsByDate(filteredReservations);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sve rezervacije'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: AppTheme.spacing16),
                    const Text(
                      'Učitavanje rezervacija...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : _reservations == null || _reservations!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 56,
                          color: AppTheme.textTertiary,
                        ),
                        SizedBox(height: AppTheme.spacing12),
                        const Text(
                          'Nema rezervacija',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // ✅ SEARCH BAR
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spacing12),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Pretraži po imenu...',
                              hintStyle: const TextStyle(
                                color: AppTheme.textTertiary,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppTheme.textSecondary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: AppTheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
                                vertical: AppTheme.spacing12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ✅ STATUS FILTER CHIPS
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spacing12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _statusOptions.map((status) {
                                final isSelected = _selectedStatus == status;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacing4),
                                  child: FilterChip(
                                    label: Text(
                                      status,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() => _selectedStatus = status);
                                    },
                                    backgroundColor:
                                        AppTheme.borderLight,
                                    selectedColor: AppTheme.primaryGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusXLarge),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.borderLight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacing12,
                                      vertical: AppTheme.spacing8,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      // ✅ SUMMARY BY DATE
                      if (filteredReservations.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTheme.spacing16),
                            child: Container(
                              padding:
                                  const EdgeInsets.all(AppTheme.spacing16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreenLight
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                border: Border.all(
                                  color: AppTheme.primaryGreenLight
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📅 Pregled po danima',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: AppTheme.spacing12),
                                  Wrap(
                                    spacing: AppTheme.spacing8,
                                    runSpacing: AppTheme.spacing8,
                                    children: groupedByDate.entries
                                        .map((entry) {
                                          final date = entry.key;
                                          final count = entry.value.length;
                                          final plural = count == 1
                                              ? 'rezervacija'
                                              : count < 5
                                                  ? 'rezervacije'
                                                  : 'rezervacija';
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.radiusSmall),
                                            ),
                                            child: Text(
                                              '$date → $count $plural',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ✅ RESERVATIONS LIST
                      if (filteredReservations.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: AppTheme.textTertiary,
                                ),
                                SizedBox(height: AppTheme.spacing12),
                                Text(
                                  _searchQuery.isNotEmpty ||
                                          _selectedStatus != 'All'
                                      ? 'Nema rezervacija koje odgovaraju filtrima'
                                      : 'Nema rezervacija',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final r = filteredReservations[index]
                                  as Map<String, dynamic>;

                              final id = r['id'];
                              final firstName = r['firstName'] ?? '';
                              final lastName = r['lastName'] ?? '';
                              final phone = r['phoneNumber'] ?? '';
                              final petName = r['petName'] ?? '';
                              final petType = r['petType'] ?? '';
                              final address = r['address'] ?? '';
                              final date = formatReservationDate(r);
                              final status = r['status'] ?? 'Pending';

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppTheme.spacing12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceWhite,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLarge),
                                    boxShadow: AppTheme.shadowMedium,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {},
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusLarge),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppTheme.spacing14),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryGreen
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                                size: 24,
                                                color: AppTheme.primaryGreen,
                                              ),
                                            ),
                                            SizedBox(width: AppTheme.spacing14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$firstName $lastName',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                      color: AppTheme
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                  SizedBox(height: AppTheme.spacing6),
                                                  Text(
                                                    '📞 $phone',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(height: AppTheme.spacing4),
                                                  Text(
                                                    '🐕 $petName ($petType)',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(height: AppTheme.spacing4),
                                                  Text(
                                                    '📍 $address',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme
                                                          .textTertiary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          AppTheme.spacing6),
                                                  Text(
                                                    '📅 $date',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme
                                                          .primaryGreen,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                                width: AppTheme.spacing12),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                // ✅ STATUS BADGE
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal:
                                                        AppTheme.spacing10,
                                                    vertical:
                                                        AppTheme.spacing6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getStatusColor(status),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppTheme
                                                                .radiusXLarge),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: AppTheme.spacing8),
                                                PopupMenuButton<String>(
                                                  icon: const Icon(
                                                    Icons.more_vert,
                                                    color:
                                                        AppTheme.textSecondary,
                                                    size: 20,
                                                  ),
                                                  onSelected:
                                                      (value) async {
                                                    try {
                                                      if (value == 'confirm') {
                                                        await _updateStatus(
                                                            id, 'Confirmed');
                                                      } else if (value ==
                                                          'reject') {
                                                        await _updateStatus(
                                                            id, 'Cancelled');
                                                      } else if (value ==
                                                          'delete') {
                                                        await context
                                                            .read<
                                                                ReservationProvider>()
                                                            .deleteReservation(
                                                                id);
                                                        setState(() {
                                                          _reservations!
                                                              .removeWhere(
                                                                  (res) =>
                                                                      res['id'] ==
                                                                      id);
                                                        });
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                                '✅ Rezervacija obrisana'),
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Greška: $e')),
                                                      );
                                                    }
                                                  },
                                                  itemBuilder: (_) => const [
                                                    PopupMenuItem(
                                                      value: 'confirm',
                                                      child: Text('✅ Potvrdi'),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'reject',
                                                      child: Text('❌ Odbij'),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text('🗑 Izbriši'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: filteredReservations.length,
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
