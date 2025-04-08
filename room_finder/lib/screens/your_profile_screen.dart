import 'package:flutter/material.dart';

class YourProfileScreen extends StatelessWidget {
  const YourProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: const Center(
        child: Text('Profile Screen Placeholder'),
      ),
    );
  }
}
