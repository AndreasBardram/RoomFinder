import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'chat_screen.dart';
import '../utils/navigation.dart';

class MoreInformationScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String parentCollection;
  final String parentId;

  const MoreInformationScreen({
    super.key,
    required this.data,
    required this.parentCollection,
    required this.parentId,
  });

  // ---- image fetching from Firestore/Storage ----
  Future<List<String>> _fetchImageUrls() async {
    final q = await FirebaseFirestore.instance
        .collection('images')
        .where('parentCollection', isEqualTo: parentCollection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('index')
        .limit(6)
        .get();
    return q.docs.map((d) => (d.data()['url'] as String)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Uden titel').toString();
    final location = (data['location'] ?? 'Ukendt').toString();
    final price = ((data['price'] ?? 0) as num).toDouble();
    final size = ((data['size'] ?? 0) as num).toDouble();
    final period = (data['period'] ?? '').toString();
    final roommates = ((data['roommates'] ?? 0) as num).toInt();
    final description = (data['description'] ?? '').toString();

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
        centerTitle: true, // visually centered between back and right side
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        // Invisible action to balance the default leading back button width
        actions: const [
          Opacity(
            opacity: 0,
            child: IconButton(onPressed: null, icon: Icon(Icons.arrow_back)),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchImageUrls(),
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          final images = snap.data ?? const <String>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3, // a bit taller than 16:9
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: loading ? const _SkeletonImage() : _UrlImagesPager(urls: images),
                  ),
                ),
                const SizedBox(height: 16),
                Text(location, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text('DKK $priceStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _iconRow(const Icon(FluentIcons.ruler_24_regular, size: 18, color: Colors.black87), '${size.toStringAsFixed(0)} m²'),
                _iconRow(const Icon(FluentIcons.calendar_24_regular, size: 18, color: Colors.black87),
                    period.isEmpty ? 'Periode: —' : 'Periode: $period'),
                _iconRow(const Icon(FluentIcons.people_24_regular, size: 18, color: Colors.black87), 'Roommates: $roommates'),
                const SizedBox(height: 8),
                Text('Oprettet: $createdStr', style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2))),
                const SizedBox(height: 16),
                if (description.isNotEmpty) Text(description, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 24),
                _applyButton(context),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      // Neutral bottom nav (no animation on tap)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
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
          child: const Text('Send besked'),
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
      // ignore: use_build_context_synchronously
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

class _UrlImagesPager extends StatefulWidget {
  final List<String> urls;
  const _UrlImagesPager({required this.urls});

  @override
  State<_UrlImagesPager> createState() => _UrlImagesPagerState();
}

class _UrlImagesPagerState extends State<_UrlImagesPager> {
  final _controller = PageController();
  int _i = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int dir) {
    final len = widget.urls.length;
    if (len <= 1) return;
    final next = (_i + dir).clamp(0, len - 1);
    if (next == _i) return;
    _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final len = widget.urls.length;
    if (len == 0) return const _SkeletonImage();

    final leftEnabled = _i > 0;
    final rightEnabled = _i < len - 1;

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          physics: len > 1 ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
          onPageChanged: (v) => setState(() => _i = v),
          itemCount: len,
          itemBuilder: (_, idx) => Image.network(
            widget.urls[idx],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          ),
        ),
        if (leftEnabled)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _NavButton(icon: Icons.chevron_left, onPressed: () => _go(-1)),
            ),
          ),
        if (rightEnabled)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _NavButton(icon: Icons.chevron_right, onPressed: () => _go(1)),
            ),
          ),
      ],
    );
  }
}

// Compact, consistent nav button (28x28, icon 16)
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(child: Icon(icon, size: 16, color: Colors.white)),
        ),
      ),
    );
  }
}

class _SkeletonImage extends StatelessWidget {
  const _SkeletonImage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFFE5E7EB));
  }
}

// No-animation route helper
PageRoute _noAnimRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
