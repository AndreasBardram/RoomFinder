import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import '../components/apartment_card.dart';
import 'settings_screen.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';
import 'edit_profile_screen.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});
  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _firstName = '';
  String _lastName = '';
  String _birthDate = '';
  String _phone = '';
  String _email = '';
  String _imageUrl = '';
  String _intent = '';
  String _social = '';
  String _bio = '';
  int? _age;
  bool _loading = true;

  int? _calcAge(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return null;
    final now = DateTime.now();
    var y = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) y--;
    return y;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!snap.exists) {
      setState(() => _loading = false);
      return;
    }
    final d = snap.data()!;
    final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _firstName = d['firstName']?.toString() ?? '';
      _lastName = d['lastName']?.toString() ?? '';
      _birthDate = meta['birthDate']?.toString() ?? d['birthDate']?.toString() ?? '';
      _phone = meta['phone']?.toString() ?? d['phone']?.toString() ?? '';
      _imageUrl = d['imageUrl']?.toString() ?? '';
      _intent = meta['intent']?.toString() ?? '';
      _social = meta['social']?.toString() ?? d['social']?.toString() ?? '';
      _bio = meta['bio']?.toString() ?? d['bio']?.toString() ?? '';
      _email = user.email ?? '';
      _age = _calcAge(_birthDate);
      _loading = false;
    });
  }

  String _displayOrDash(String v) => v.trim().isEmpty ? '—' : v.trim();

  Widget _intentChip() {
    String label;
    if (_intent == 'rent') {
      label = 'Jeg vil leje';
    } else if (_intent == 'rentOut') {
      label = 'Jeg vil udleje';
    } else {
      label = 'Ikke valgt';
    }
    return Chip(label: Text(label));
  }

  Widget _header() {
    final name = [_firstName, _lastName].where((s) => s.trim().isNotEmpty).join(' ');
    final nameAge = [
      name.trim(),
      if (_age != null) '$_age år',
    ].where((s) => s.isNotEmpty).join(', ');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned.fill(
              child: _imageUrl.isNotEmpty
                  ? Image.network(_imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.6, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                      child: _imageUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nameAge.isNotEmpty)
                          Text(
                            nameAge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        const SizedBox(height: 8),
                        _intentChip(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(_displayOrDash(value), style: const TextStyle(fontSize: 16)),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Din profil')),
        body: _loggedOut(context),
      );
    }
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Din profil'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(alignment: Alignment.centerLeft, child: Text('Kontakt og info', style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(height: 12),
                    _infoRow(Icons.mail_outline, 'E-mail', _email),
                    const Divider(height: 1),
                    _infoRow(Icons.phone_outlined, 'Telefonnummer', _phone),
                    const Divider(height: 1),
                    _infoRow(Icons.event_outlined, 'Fødselsdato', _birthDate),
                    const Divider(height: 1),
                    _infoRow(Icons.public, 'Social media', _social),
                    const SizedBox(height: 16),
                    Align(alignment: Alignment.centerLeft, child: Text('Beskrivelse', style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _displayOrDash(_bio.length > 200 ? _bio.substring(0, 200) : _bio),
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButtonContainer(
                        child: ElevatedButton(
                          style: customElevatedButtonStyle(),
                          onPressed: () async {
                            final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            if (changed == true) await _loadProfile();
                          },
                          child: const Text('Rediger profil'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Dine opslag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(DateTime.now()),
              future: FirebaseFirestore.instance.collection('apartments').where('ownedBy', isEqualTo: uid).get(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text('Fejl: ${snap.error}'),
                  );
                }
                final docs = snap.data?.docs ?? [];
                docs.sort((a, b) {
                  final tA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  final tB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  return tB.compareTo(tA);
                });
                if (docs.isEmpty) {
                  return Column(
                    children: const [
                      Icon(FluentIcons.home_24_regular, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ingen aktive opslag.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  );
                }
                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    const count = 2;
                    const hPad = 8.0;
                    const spacing = 16.0;
                    final w = (constraints.maxWidth - hPad * 2 - spacing * (count - 1)) / count;
                    final h = w + 124;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: h,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i].data();
                        final images = (d['imageUrls'] as List?)?.whereType<String>().toList() ?? [];
                        return ApartmentCard(
                          images: images,
                          title: d['title'] ?? '',
                          location: d['location'] ?? 'Ukendt',
                          price: d['price'] ?? 0,
                          size: (d['size'] ?? 0).toDouble(),
                          period: d['period'] ?? '',
                          roommates: (d['roommates'] ?? 0) as int,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _loggedOut(BuildContext ctx) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: CustomButtonContainer(
                child: ElevatedButton(
                  style: customElevatedButtonStyle(),
                  onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Log ind'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: CustomButtonContainer(
                child: ElevatedButton(
                  style: customElevatedButtonStyle(),
                  onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                  child: const Text('Opret profil'),
                ),
              ),
            ),
          ],
        ),
      );
}
