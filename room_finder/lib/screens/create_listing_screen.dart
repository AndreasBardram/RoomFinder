import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'settings_screen.dart'; 
import '../components/custom_styles.dart';

/// Common InputDecoration for all TextFields.
InputDecoration customInputDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(
      color: Color.fromARGB(255, 100, 100, 100),
      fontSize: 14,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color.fromARGB(255, 100, 100, 100),
      fontSize: 14,
    ),
    border: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 180, 180, 180)),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 180, 180, 180)),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 180, 180, 180)),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
  );
}

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

class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () {
              // Navigate to the Settings screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Apartment Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: customInputDecoration(labelText: 'Apartment Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: customInputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: customInputDecoration(labelText: 'Price (in \$)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: customInputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: customInputDecoration(labelText: 'Contact Info'),
            ),
            const SizedBox(height: 32),
            CustomButtonContainer(
              margin: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Handle listing creation logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing Created')),
                  );
                },
                style: customElevatedButtonStyle(),
                child: const Text('Create Listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
