import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
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
    final title = (data['title'] ?? 'Uden titel').toString();
    final location = (data['location'] ?? 'Ukendt').toString();
    final price = (data['price'] ?? 0).toDouble();
    final size = (data['size'] ?? 0).toDouble();
    final period = (data['period'] ?? '').toString();
    final roommates = (data['roommates'] ?? 0) as int;
    final description = (data['description'] ?? '').toString();
    final images = List<String>.from(data['imageUrls'] ?? []);

    DateTime? created;
    final ca = data['createdAt'];
    if (ca is Timestamp) created = ca.toDate();
    final createdStr = created != null
        ? DateFormat('d. MMMM y • HH:mm', 'da_DK').format(created.toLocal())
        : 'Ukendt tidspunkt';

    final priceStr = NumberFormat.decimalPattern('da_DK').format(price.round());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageCarousel(images),
            const SizedBox(height: 16),
            Text(location, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text('DKK $priceStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _iconRow(const Icon(FluentIcons.ruler_24_regular, size: 18, color: Colors.black87), '${size.toStringAsFixed(0)} m²'),
            _iconRow(const Icon(FluentIcons.calendar_24_regular, size: 18, color: Colors.black87), period.isEmpty ? '—' : period),
            _iconRow(const Icon(FluentIcons.people_24_regular, size: 18, color: Colors.black87), roommates.toString()),
            const SizedBox(height: 8),
            Text('Oprettet: $createdStr', style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2))),
            const SizedBox(height: 16),
            if (description.isNotEmpty) Text(description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            _applyButton(context),
            const SizedBox(height: 8),
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
        height: 240,
        child: images.isEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(color: const Color(0xFFE5E7EB), child: const Center(child: Icon(Icons.photo, size: 56, color: Colors.white))),
              )
            : PageView.builder(
                itemCount: images.length,
                controller: PageController(viewportFraction: 1),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFFE5E7EB)),
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFFE5E7EB)),
                  ),
                ),
              ),
      );

  Widget _iconRow(Widget icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(child: Text(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );

  Widget _applyButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
