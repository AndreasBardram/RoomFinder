import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

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
    final ts          = data['createdAt'];
    DateTime? created;
    if (ts != null) {
      created = DateTime.fromMillisecondsSinceEpoch(
          ts.millisecondsSinceEpoch,
          isUtc: true);
    }
    final createdStr = created != null
        ? DateFormat('d. MMMM y • HH:mm', 'da').format(created.toLocal())
        : 'Ukendt tidspunkt';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 260,
              child: images.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Icon(Icons.photo, size: 60)))
                  : PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.grey[200]),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(location,
                style: GoogleFonts.roboto(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('DKK ${price.toStringAsFixed(0)}',
                style: GoogleFonts.roboto(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('📏 ', style: TextStyle(fontSize: 16)),
                Text('${size.toStringAsFixed(0)} m²',
                    style: GoogleFonts.roboto(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('📆 ', style: TextStyle(fontSize: 16)),
                Text(period, style: GoogleFonts.roboto(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('👥 ', style: TextStyle(fontSize: 16)),
                Text(roommates.toString(),
                    style: GoogleFonts.roboto(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Oprettet: $createdStr',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            Text(description, style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showConfirm(context),
                child: const Text('Send ansøgning',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send ansøgning?'),
        content: const Text('Bekræft for at åbne chatten og sende ansøgningen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
            child: const Text('Bekræft'),
          ),
        ],
      ),
    );
  }
}
