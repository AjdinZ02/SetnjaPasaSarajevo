import 'dart:convert';
import 'dart:io';

import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/pet_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/user_provider.dart';
import 'package:setnjapasasarajevo_mobile/screens/add_pet_screen.dart';
import 'package:setnjapasasarajevo_mobile/screens/change_password_screen.dart';
import 'package:setnjapasasarajevo_mobile/screens/notifications_screen.dart';
import 'package:setnjapasasarajevo_mobile/screens/profile_settings_screen.dart';
import 'package:setnjapasasarajevo_mobile/utils/utils_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:setnjapasasarajevo_mobile/utils/app_theme.dart';
import '../models/pet.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProvider _userProvider;
  late PetProvider _petProvider;

  User? user;

  bool isLoading = true;
  bool petsLoading = true;
  bool isUploading = false;

  List<Pet> pets = [];

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _petProvider = context.read<PetProvider>();
    initData();
  }

  Future<void> initData() async {
    int userId =
        int.tryParse(
          AuthProvider.accessTokenDecoded?['Id']?.toString() ?? '',
        ) ??
        0;

    try {
      final results = await Future.wait([
        _userProvider.getById(userId, forceRefresh: true),
        _petProvider.getMyPets(),
      ]);

      if (!mounted) return;

      setState(() {
        user = results[0] as User;
        pets = results[1] as List<Pet>;
        isLoading = false;
        petsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        petsLoading = false;
      });
    }
  }

  Future<void> _selectImageSource() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Galerija"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Kamera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 50);

    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(sourcePath: picked.path);

    if (cropped == null) return;

    final bytes = await File(cropped.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      setState(() => isUploading = true);

      await context.read<UserProvider>().uploadImage({"image": base64Image});

      if (!mounted) return;

      setState(() {
        _selectedImage = File(cropped.path);
        isUploading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Slika uploadana ✅")));
    } catch (e) {
      setState(() => isUploading = false);
      alertBox(context, "Greška", e.toString());
    }
  }

  Future<void> refreshPets() async {
    if (!mounted) return;
    setState(() => petsLoading = true);

    final data = await _petProvider.getMyPets();

    if (!mounted) return;

    setState(() {
      pets = data ?? [];
      petsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: RefreshIndicator(
        onRefresh: refreshPets,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
          children: [
            // ✅ NEMA SPINNER — uvijek prikaz
            _buildProfileInfo(),
            const SizedBox(height: 20),
            _buildMyPetsSection(),
            const SizedBox(height: 20),
            _buildProfileMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final tokenData = AuthProvider.accessTokenDecoded;

    final displayName = user != null
        ? "${user?.firstName ?? ""} ${user?.lastName ?? ""}"
        : "${tokenData?['FirstName'] ?? ''} ${tokenData?['LastName'] ?? ''}";

    final username = user?.username ?? tokenData?['Username'] ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.8, end: 1),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: GestureDetector(
              onTap: _selectImageSource,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (user?.profileImageBase64 != null
                            ? ImageFromBase64StringWithoutDimnesions(
                                user!.profileImageBase64!,
                              )
                            : null),
                  child: isUploading
                      ? const CircularProgressIndicator()
                      : (_selectedImage == null &&
                                user?.profileImageBase64 == null
                            ? const Icon(Icons.person, size: 40)
                            : null),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            username,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPetsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Moje životinje',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final shouldRefresh = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPetScreen()),
                  );
                  if (shouldRefresh == true) await refreshPets();
                },
                icon: const Icon(Icons.add, size: 19),
                label: const Text('Dodaj'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreenDark,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (petsLoading)
            const Center(child: CircularProgressIndicator())
          else if (pets.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 36,
                    color: AppTheme.textTertiary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Još nemate dodanih životinja',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...pets.map(
              (pet) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: AppTheme.shadowSmall,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenLight.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: AppTheme.primaryGreenDark,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pet.type} • ${pet.age} god.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuItem(Icons.edit, "Uredi profil", () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSettingsScreen(user: user!),
                ),
              );
              if (updated == true && mounted) {
                await initData();
              }
            }),
            _buildDivider(),
            _buildMenuItem(Icons.lock_outline, "Promijeni lozinku", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
              );
            }),
            _buildDivider(),
            _buildMenuItem(Icons.notifications_none, "Obavijesti", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            }),
            _buildDivider(),
            _buildMenuItem(Icons.logout, "Odjava", () {
              context.read<AuthProvider>().logout(context);
              Navigator.of(context).popUntil((r) => r.isFirst);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }
}
