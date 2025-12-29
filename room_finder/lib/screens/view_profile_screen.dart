import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'chat_screen.dart';
import 'more_information_apartment.dart';
import '../utils/navigation.dart'; // for MainScreen

class ViewProfileScreen extends StatelessWidget {
  final String userId;
  const ViewProfileScreen({super.key, required this.userId});

  int? _ageFromBirthDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final now = DateTime.now();
    var y = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) y--;
    return y;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final d = snap.data?.data();
        if (d == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: const Center(child: Text('Profil ikke fundet')),
          );
        }

        final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
        final first = (d['firstName'] ?? '').toString();
        final last = (d['lastName'] ?? '').toString();
        final name = ('$first $last').trim().isEmpty ? 'Profil' : ('$first $last').trim();
        final imageUrl = (d['imageUrl'] ?? '').toString();
        final email = (meta['email'] ?? d['email'] ?? '').toString();
        final phone = (meta['phone'] ?? d['phone'] ?? '').toString();
        final birth = (meta['birthDate'] ?? d['birthDate'] ?? '').toString();
        final social = (meta['social'] ?? '').toString();
        final profileType = (meta['profileType'] ?? '').toString();
        final age = _ageFromBirthDate(birth);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
            iconTheme: const IconThemeData(color: Colors.black),
            title: const Text('Profil'),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(color: const Color(0xFFE5E7EB), child: const Center(child: Icon(Icons.person, size: 56, color: Colors.white))),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          height: 56,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x88000000)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Text(
                        age != null ? '$name, $age år' : name,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _infoRow(FluentIcons.person_24_regular, name),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _infoRow(FluentIcons.call_24_regular, phone.isEmpty ? '—' : phone),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _infoRow(FluentIcons.mail_24_regular, email.isEmpty ? '—' : email),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _infoRow(FluentIcons.calendar_24_regular, birth.isEmpty ? '—' : birth),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _infoRow(FluentIcons.globe_24_regular, social.isEmpty ? '—' : social),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _infoRow(FluentIcons.tag_24_regular, profileType.isEmpty ? '—' : (profileType == 'landlord' ? 'Udlejer' : 'Lejer')),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Start chat (disabled if self)
              _ChatButton(targetUserId: userId, targetName: name),

              const SizedBox(height: 24),

              // Only show landlord's apartments. If not landlord, show nothing.
              _UserApartmentsOnly(userId: userId, profileType: profileType),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 3, // "Min Profil" tab selected
            onTap: (i) => Navigator.pushAndRemoveUntil(
              context,
              _noAnimRoute(MainScreen(initialIndex: i)),
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
              BottomNavigationBarItem(icon: Icon(FluentIcons.search_24_regular), label: 'Find Værelse'),
              BottomNavigationBarItem(icon: Icon(FluentIcons.add_24_regular), label: 'Opret'),
              BottomNavigationBarItem(icon: Icon(FluentIcons.chat_24_regular), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(FluentIcons.person_24_regular), label: 'Min Profil'),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final String targetUserId;
  final String targetName;
  const _ChatButton({required this.targetUserId, required this.targetName});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final isSelf = me != null && me.uid == targetUserId;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(FluentIcons.chat_24_regular),
        label: Text(isSelf ? 'Det er dig' : 'Start chat med $targetName'),
        onPressed: isSelf
            ? null
            : () async {
                final userSnap = await FirebaseFirestore.instance.collection('users').doc(targetUserId).get();
                if (!userSnap.exists) return;
                final d = userSnap.data()!;
                final other = types.User(
                  id: targetUserId,
                  firstName: d['firstName'],
                  lastName: d['lastName'],
                  imageUrl: d['imageUrl'],
                  metadata: d,
                );
                final room = await FirebaseChatCore.instance.createRoom(other);
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(room: room)));
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Only shows apartments if the profile is a landlord. Otherwise shows nothing.
class _UserApartmentsOnly extends StatelessWidget {
  final String userId;
  final String profileType; // 'landlord' or something else
  const _UserApartmentsOnly({required this.userId, required this.profileType});

  @override
  Widget build(BuildContext context) {
    final isLandlord = profileType.toLowerCase() == 'landlord';
    if (!isLandlord) return const SizedBox.shrink();

    const header = 'Opslag'; // apartments

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(header, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('apartments')
              .where('ownedBy', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(20)
              .get(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Ingen opslag.'),
              );
            }
            return ListView.separated(
              itemCount: docs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, i) {
                final d = docs[i].data();
                final id = docs[i].id;
                final title = (d['title'] ?? '').toString();
                final subtitle = '${(d['location'] ?? 'Ukendt')} • ${(d['size'] ?? 0)} m²';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(subtitle.toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      _,
                      MaterialPageRoute(
                        builder: (_) => MoreInformationScreen(
                          data: d,
                          parentCollection: 'apartments',
                          parentId: id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// No-animation route helper
PageRoute _noAnimRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
