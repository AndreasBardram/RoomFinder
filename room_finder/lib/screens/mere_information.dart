import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MoreInformationScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const MoreInformationScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title       = data['title'] ?? 'Uden titel';
    final location    = data['location'] ?? 'Ukendt';
    final price       = (data['price'] ?? 0).toDouble();
    final size        = (data['size'] ?? 0).toDouble();
    final period      = data['period'] ?? '';
    final roommates   = (data['roommates'] ?? 0) as int;
    final description = data['description'] ?? '';
    final images      = List<String>.from(data['imageUrls'] ?? []);
    final createdAtTs = data['createdAt'];
    DateTime? createdAt;
    if (createdAtTs != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
          createdAtTs.millisecondsSinceEpoch,
          isUtc: true);
    }
    final createdStr = createdAt != null
        ? DateFormat('d. MMMM y • HH:mm').format(createdAt.toLocal())
        : 'Ukendt tidspunkt';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              child: images.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Icon(Icons.image, size: 60)),
                    )
                  : PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[200],
                            child:
                                const Center(child: Icon(Icons.image, size: 60)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.broken_image, size: 60)),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(location,
                    style: GoogleFonts.roboto(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('DKK ${price.toStringAsFixed(0)}',
                    style: GoogleFonts.roboto(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Størrelse: ${size.toStringAsFixed(0)} m²',
                style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Periode: $period',
                style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Roommates: $roommates',
                style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Oprettet: $createdStr',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Text(description, style: GoogleFonts.roboto(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
