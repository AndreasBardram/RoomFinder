import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'settings_screen.dart';

/* ---------------- Apartment card ---------------- */

class ApartmentCard extends StatelessWidget {
  final String city;
  final double price;

  const ApartmentCard({
    super.key,
    required this.city,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // Placeholder for a future image
            Container(
              color: Colors.grey[200],
              height: 100,
              child: const Center(child: Icon(Icons.image, size: 50)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                city,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '\$${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Screen ---------------- */

class FindRoommatesScreen extends StatelessWidget {
  const FindRoommatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('apartments')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Roommates'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No apartments available.'));
          }

          final docs = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data  = docs[i].data();
              final city  = data['city'] ?? 'Unknown';
              final price = (data['price'] ?? 0).toDouble();

              return ApartmentCard(city: city, price: price);
            },
          );
        },
      ),
    );
  }
}
