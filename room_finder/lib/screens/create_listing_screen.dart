import 'package:flutter/material.dart';

class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
      ),
      body: const Center(
        child: Text('Create a new listing here'),
      ),
    );
  }
}
