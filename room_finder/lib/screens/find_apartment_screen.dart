import 'package:flutter/material.dart';

class FindApartmentScreen extends StatelessWidget {
  const FindApartmentScreen({Key? key}) : super(key: key);

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Apartment')),
      body: const Center(
        child: Text('Find Apartment'),
      ),
    );
  }
}
