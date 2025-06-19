// more_information.dart
//
// Full–detail view of one apartment listing.
// Expects a `DocumentSnapshot<Map<String, dynamic>>` called `doc`.
//
// Add `cached_network_image` to pubspec.yaml (already done in list screen).
//

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoreInformationScreen extends StatelessWidget {
  final Map<String, dynamic> data;   // the apartment fields

  const MoreInformationScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    /* ------- parse fields with fall-backs ------- */
    final title       = data['title']       ?? 'Untitled';
    final city        = data['city']        ?? 'Unknown';
    final price       = (data['price']      ?? 0).toDouble();
    final roommates   = (data['roommates']  ?? 0).toInt();
    final description = data['description'] ?? '';
    final images      = List<String>.from(data['imageUrls'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* ---- image carousel ---- */
            if (images.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.image, size: 60)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                            child: Icon(Icons.broken_image, size: 60)),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    const Center(child: Icon(Icons.image, size: 60)),
              ),
            const SizedBox(height: 24),

            /* ---- city & price ---- */
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  city,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'DKK ${price.toStringAsFixed(0)}',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /* ---- roommates ---- */
            Text('Room-mates allowed: $roommates',
                style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 16),

            /* ---- description ---- */
            Text(
              description,
              style: GoogleFonts.roboto(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
