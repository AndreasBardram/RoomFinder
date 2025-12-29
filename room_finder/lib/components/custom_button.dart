import 'package:flutter/material.dart';

/// Common ElevatedButton style.
ButtonStyle customElevatedButtonStyle() {
  return ElevatedButton.styleFrom(
    foregroundColor: Colors.black,     // Text color
    backgroundColor: Colors.white,     // Button background color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    padding: const EdgeInsets.symmetric(vertical: 15.0),
    elevation: 2,
  );
}


/// A reusable Setting Button that matches the look of your original custom SettingScreen.
Widget customSettingButton({
  required BuildContext context,
  required String label,
  required VoidCallback onPressed,
}) {
  return Container(
    height: 50,
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: ElevatedButton(
        onPressed: onPressed,
        style: customElevatedButtonStyle(),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontSize: 16, color: Colors.black),
        ),
      ),
    ),
  );
}
