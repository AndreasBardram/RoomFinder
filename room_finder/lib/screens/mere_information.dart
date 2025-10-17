import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'chat_screen.dart';
import '../utils/navigation.dart';

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

    DateTime? created;
    if (data['createdAt'] != null) {
      created = DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'].millisecondsSinceEpoch,
        isUtc: true,
      );
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
            _imageCarousel(images),
            const SizedBox(height: 20),
            Text(location, style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('DKK ${price.toStringAsFixed(0)}', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow('📏 ', '${size.toStringAsFixed(0)} m²'),
            _infoRow('📆 ', period),
            _infoRow('👥 ', roommates.toString()),
            const SizedBox(height: 4),
            Text('Oprettet: $createdStr', style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            Text(description, style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 30),
            _applyButton(context),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (i) => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(initialIndex: i)),
          (route) => false,
        ),
        showUnselectedLabels: true,
        selectedItemColor: Colors.grey[600],
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedIconTheme: const IconThemeData(size: 25),
        unselectedIconTheme: const IconThemeData(size: 25),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FluentIcons.search_24_regular),
            label: 'Find Værelse',
          ),
          BottomNavigationBarItem(
            icon: Icon(FluentIcons.add_24_regular),
            label: 'Opret',
          ),
          BottomNavigationBarItem(
            icon: Icon(FluentIcons.chat_24_regular),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(FluentIcons.person_24_regular),
            label: 'Min Profil',
          ),
        ],
      ),
    );
  }

  Widget _imageCarousel(List<String> images) => SizedBox(
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
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                  ),
                ),
              ),
      );

  Widget _infoRow(String icon, String text) => Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          Text(text, style: GoogleFonts.roboto(fontSize: 16)),
        ],
      );

  Widget _applyButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () => _startChat(context),
          child: const Text('Send ansøgning'),
        ),
      );

  Future<void> _startChat(BuildContext context) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final ownerUid = data['ownedBy'] as String?;
    if (ownerUid == null || ownerUid == me.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Du kan ikke chatte med dig selv.')));
      return;
    }
    final ownerSnap = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();
    if (!ownerSnap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brugerprofil ikke fundet.')));
      return;
    }
    final d = ownerSnap.data()!;
    final owner = types.User(
      id: ownerUid,
      firstName: d['firstName'],
      lastName: d['lastName'],
      imageUrl: d['imageUrl'],
      metadata: d,
    );
    final room = await FirebaseChatCore.instance.createRoom(owner);
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(room: room)));
  }
}
