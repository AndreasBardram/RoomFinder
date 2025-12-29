import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'chat_screen.dart';
import 'view_profile_screen.dart';
import '../utils/navigation.dart';
import '../components/no_transition.dart'; 

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

  Future<List<String>> _thumbsFor(String collection, String id) async {
    final q = await FirebaseFirestore.instance
        .collection('images')
        .where('parentCollection', isEqualTo: collection)
        .where('parentId', isEqualTo: id)
        .orderBy('index')
        .limit(3)
        .get();
    return q.docs.map((d) => (d.data()['url'] as String)).toList();
  }

  Future<String?> _firstImageUrl(String collection, String id) async {
    final q = await FirebaseFirestore.instance
        .collection('images')
        .where('parentCollection', isEqualTo: collection)
        .where('parentId', isEqualTo: id)
        .orderBy('index')
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['url'] as String);
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
    final ownerUid = data['ownedBy'] as String?;
    final meUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwn = ownerUid != null && ownerUid == meUid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [
          Opacity(opacity: 0, child: IconButton(onPressed: null, icon: Icon(Icons.arrow_back))),
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
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: loading ? const _SkeletonImage() : _UrlImagesPager(urls: images),
                  ),
                ),
                const SizedBox(height: 12),
                if (ownerUid != null) _UploaderTile(ownerUid: ownerUid),
                const SizedBox(height: 12),
                Text(location, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text('DKK $priceStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _iconRow(const Icon(FluentIcons.ruler_24_regular, size: 18, color: Colors.black87), '${size.toStringAsFixed(0)} m²'),
                _iconRow(const Icon(FluentIcons.calendar_24_regular, size: 18, color: Colors.black87), period.isEmpty ? 'Periode: —' : 'Periode: $period'),
                _iconRow(const Icon(FluentIcons.people_24_regular, size: 18, color: Colors.black87), 'Roommates: $roommates'),
                const SizedBox(height: 8),
                Text('Oprettet: $createdStr', style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2))),
                const SizedBox(height: 16),
                if (description.isNotEmpty) Text(description, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 24),
                if (!isOwn) _applyButton(context),
                if (!isOwn) const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (i) => pushAndRemoveAllNoAnim(context, MainScreen(initialIndex: i)),
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
          onPressed: () => _startChatWithOptionalAttachment(context),
          child: const Text('Send besked'),
        ),
      );

  Future<void> _startChatWithOptionalAttachment(BuildContext context) async {
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

    final selection = await _selectAttachment(context, collection: 'applications', title: 'Vedhæft en af dine ansøgninger?');
    final d = ownerSnap.data()!;
    final owner = types.User(
      id: ownerUid,
      firstName: d['firstName'],
      lastName: d['lastName'],
      imageUrl: d['imageUrl'],
      metadata: d,
    );
    final room = await FirebaseChatCore.instance.createRoom(owner);

    if (selection != null) {
      final docId = selection['id'] as String;
      final sel = selection['data'] as Map<String, dynamic>;
      final t = (sel['title'] ?? '').toString();
      final meta = {
        'collection': 'applications',
        'id': docId,
        'title': t,
        'subtitle': _appSubtitle(sel),
        'imageUrl': await _firstImageUrl('applications', docId) ?? '',
      };
      FirebaseChatCore.instance.sendMessage(types.PartialCustom(metadata: meta), room.id);
    }

    if (!context.mounted) return;
    await pushNoAnim(context, ChatScreen(room: room));
  }

  Future<Map<String, dynamic>?> _selectAttachment(BuildContext context, {required String collection, required String title}) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return null;
    final qs = await FirebaseFirestore.instance.collection(collection).where('ownedBy', isEqualTo: me.uid).get();
    if (qs.docs.isEmpty) return null;

    return await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: qs.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final doc = qs.docs[i];
                    final d = doc.data();
                    final t = (d['title'] ?? '').toString();
                    final subtitle = collection == 'apartments' ? _aptSubtitle(d) : _appSubtitle(d);
                    return FutureBuilder<List<String>>(
                      future: _thumbsFor(collection, doc.id),
                      builder: (c, s) {
                        final urls = s.data ?? const <String>[];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: _ThumbRow(urls: urls),
                          title: Text(t.isEmpty ? '(Uden titel)' : t, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, {'id': doc.id, 'data': d}),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Fortsæt uden vedhæftning')),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _aptSubtitle(Map<String, dynamic> d) {
    final price = ((d['price'] ?? 0) as num).toDouble();
    final size = ((d['size'] ?? 0) as num).toDouble();
    final priceStr = NumberFormat.decimalPattern('da_DK').format(price.round());
    final sizeStr = size.toStringAsFixed(0);
    return 'DKK $priceStr • ${sizeStr} m²';
  }

  String _appSubtitle(Map<String, dynamic> d) {
    final budget = ((d['budget'] ?? 0) as num).toDouble();
    final budgetStr = NumberFormat.decimalPattern('da_DK').format(budget.round());
    return 'Budget: DKK $budgetStr';
  }
}

class _ThumbRow extends StatelessWidget {
  final List<String> urls;
  const _ThumbRow({required this.urls});
  @override
  Widget build(BuildContext context) {
    final u = urls.take(3).toList();
    if (u.isEmpty) {
      return const _Shimmer(child: SizedBox(width: 72, height: 48, child: ColoredBox(color: Color(0xFFE5E7EB))));
    }
    return SizedBox(
      width: 84,
      child: Row(
        children: List.generate(u.length, (i) {
          return Padding(
            padding: EdgeInsets.only(right: i == u.length - 1 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(u[i], width: 36, height: 36, fit: BoxFit.cover),
            ),
          );
        }),
      ),
    );
  }
}

class _UploaderTile extends StatelessWidget {
  final String ownerUid;
  const _UploaderTile({required this.ownerUid});

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
      future: FirebaseFirestore.instance.collection('users').doc(ownerUid).get(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _UploaderSkeleton();
        }
        final d = snap.data?.data();
        if (d == null) return const SizedBox.shrink();

        final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
        final name = '${(d['firstName'] ?? '').toString()} ${(d['lastName'] ?? '').toString()}'.trim();
        final age = _ageFromBirthDate((meta['birthDate'] ?? d['birthDate'])?.toString());
        final profileType = (meta['profileType'] ?? '').toString();
        final img = (d['imageUrl'] ?? '').toString();

        final sub = [
          if (profileType.isNotEmpty) (profileType == 'landlord' ? 'Udlejer' : 'Lejer'),
          if (age != null) '$age år',
        ].join(' • ');

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => pushNoAnim(context, ViewProfileScreen(userId: ownerUid)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                child: img.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'Profil' : name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        );
      },
    );
  }
}

class _UploaderSkeleton extends StatelessWidget {
  const _UploaderSkeleton();
  @override
  Widget build(BuildContext context) {
    return const _Shimmer(
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: Color(0xFFE5E7EB)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkelBox(w: 120, h: 12),
                SizedBox(height: 6),
                _SkelBox(w: 80, h: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkelBox extends StatelessWidget {
  final double w, h;
  const _SkelBox({required this.w, required this.h});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: h,
      child: const ColoredBox(color: Color(0xFFE5E7EB)),
    );
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
    return const _Shimmer(child: ColoredBox(color: Color(0xFFE5E7EB)));
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              colors: [Color(0xFFEFF2F6), Color(0xFFF5F7FB), Color(0xFFEFF2F6)],
              stops: [0.2, 0.5, 0.8],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
