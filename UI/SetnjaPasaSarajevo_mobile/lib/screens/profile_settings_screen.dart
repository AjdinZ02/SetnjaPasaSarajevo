import 'dart:convert';
import 'package:setnjapasasarajevo_mobile/layouts/master_screen.dart';
import 'package:setnjapasasarajevo_mobile/utils/utils_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final User user;

  const ProfileSettingsScreen({super.key, required this.user});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  Map<String, dynamic> _initialValue = {};

  late UserProvider _userProvider;

  String? base64ProfileImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    base64ProfileImage = widget.user.profileImageBase64;

    _initialValue = {
      'firstName': widget.user.firstName,
      'lastName': widget.user.lastName,
      'email': widget.user.email,
      'username': widget.user.username,
      'phoneNumber': widget.user.phoneNumber,
      'address': widget.user.address,
    };

    _userProvider = context.read<UserProvider>();
  }

  Future _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        var file = result.files.first;
        var bytes = await file.xFile.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          base64ProfileImage = base64String;
        });
      }
    } catch (e) {
      alertBox(context, "Greška", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Uredi profil",
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 20),
                  _buildForm(),
                  const SizedBox(height: 25),
                  _buildSaveButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ AVATAR (moderniji)
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickFile,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey[200],
            backgroundImage: base64ProfileImage != null
                ? ImageFromBase64StringWithoutDimnesions(base64ProfileImage!)
                : null,
            child: base64ProfileImage == null
                ? const Icon(Icons.person, size: 58, color: Colors.grey)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ✅ SAVE BUTTON (MODERAN)
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: _loading
            ? null
            : () async {
                try {
                  setState(() => _loading = true);

                  final isValid = _formKey.currentState?.saveAndValidate();

                  if (!isValid!) {
                    setState(() => _loading = false);
                    return;
                  }

                  final formData = _formKey.currentState!.value;

                  await _userProvider.updateMyProfile({
                    "firstName": formData["firstName"],
                    "lastName": formData["lastName"],
                    "email": formData["email"],
                    "username": formData["username"],
                    "phoneNumber": formData["phoneNumber"],
                    "address": formData["address"],
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("✅ Profil ažuriran"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );

                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Greška: $e")));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Sačuvaj izmjene",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ✅ FORM (malo moderniji spacing)
  Widget _buildForm() {
    return FormBuilder(
      key: _formKey,
      initialValue: _initialValue,
      child: Column(
        children: [
          _buildField("firstName", "Ime"),
          _buildField("lastName", "Prezime"),
          _buildField("username", "Username"),
          _buildEmailField(),
          _buildField("phoneNumber", "Telefon", required: false),
          _buildField("address", "Adresa", required: false),
        ],
      ),
    );
  }

  Widget _buildField(String name, String label, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormBuilderTextField(
        name: name,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return mField;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormBuilderTextField(
        name: "email",
        decoration: InputDecoration(
          labelText: "Email",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return mField;
          } else if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
          ).hasMatch(value)) {
            return "Nevalidan email";
          }
          return null;
        },
      ),
    );
  }
}
