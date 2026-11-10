import 'package:flutter/material.dart';

void showSnackbar({required BuildContext context, required Widget content}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: content));
}
