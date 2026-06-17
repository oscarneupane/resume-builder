import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  MediaQueryData get media => MediaQuery.of(this);

  void showSnack(String msg) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

extension StringX on String {
  String get capitalized => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
