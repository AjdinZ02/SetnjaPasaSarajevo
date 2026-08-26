import 'package:flutter/material.dart';

class MasterScreen extends StatelessWidget {
  final Widget child;
  final String title;

  const MasterScreen({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: child,
    );
  }
}