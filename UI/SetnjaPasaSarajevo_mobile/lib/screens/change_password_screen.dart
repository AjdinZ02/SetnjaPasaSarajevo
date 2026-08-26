import 'package:setnjapasasarajevo_mobile/layouts/master_screen.dart';
import 'package:setnjapasasarajevo_mobile/utils/utils_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Promijeni lozinku",
      child: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: "password",
                      obscureText: true,
                      decoration:
                          _inputDecoration("Trenutna lozinka", Icons.lock),
                      validator: (value) {
                        if (value == null || value.isEmpty) return mField;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: "newPassword",
                      obscureText: true,
                      decoration:
                          _inputDecoration("Nova lozinka", Icons.lock_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) return mField;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: "confirmPassword",
                      obscureText: true,
                      decoration:
                          _inputDecoration("Potvrdi lozinku", Icons.check),
                      validator: (value) {
                        if (value == null || value.isEmpty) return mField;
                        if (value !=
                            _formKey.currentState?.value['newPassword']) {
                          return "Lozinke se ne poklapaju";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          _formKey.currentState?.save();

                          try {
                            if (_formKey.currentState!.validate()) {
                              await _userProvider.changePassword({
                                'id': AuthProvider
                                    .accessTokenDecoded?['Id'],
                                'password': _formKey
                                    .currentState?.value['password'],
                                'newPassword': _formKey
                                    .currentState?.value['newPassword'],
                                'confirmNewPassword': _formKey
                                    .currentState
                                    ?.value['confirmPassword'],
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Lozinka uspješno promijenjena ✅"),
                                ),
                              );

                              Navigator.pop(context);
                            }
                          } catch (e) {
                            alertBox(context, "Greška", e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          "Sačuvaj",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
