import 'package:flutter/material.dart';

class FindRoommateScreen extends StatelessWidget {
  const FindRoommateScreen({Key? key}) : super(key: key);

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Roommate')),
      body: const Center(
        child: Text('Find Roommate'),
      ),
    );
  }
}
