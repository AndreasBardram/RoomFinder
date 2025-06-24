import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'more_information.dart';
import 'settings_screen.dart';

class ApartmentCard extends StatelessWidget {
  final String location;
  final double price;
  final String? imageUrl;
  const ApartmentCard({
    super.key,
    required this.location,
    required this.price,
    this.imageUrl,
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
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            SizedBox(
              height: 100,
              width: double.infinity,
              child: imageUrl == null
                  ? Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, size: 50)),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.image, size: 50)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child:
                            const Center(child: Icon(Icons.broken_image, size: 50)),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                location,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'DKK ${price.toStringAsFixed(0)}',
                style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FindRoommatesScreen extends StatefulWidget {
  const FindRoommatesScreen({super.key});

  @override
  State<FindRoommatesScreen> createState() => _FindRoommatesScreenState();
}

class _FindRoommatesScreenState extends State<FindRoommatesScreen> {
  String _sort = 'Newest first';
  String? _location;
  static const double _priceMin = 0;
  static const double _priceMax = 10000;
  static const int _matesMin = 0;
  static const int _matesMax = 10;
  RangeValues _price = const RangeValues(_priceMin, _priceMax);
  RangeValues _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('apartments');
    if (_location != null) {
      q = q.where('location', isEqualTo: _location);
    }
    final bool priceNarrowed =
        _price.start > _priceMin || _price.end < _priceMax;
    if (priceNarrowed) {
      q = q
          .where('price', isGreaterThanOrEqualTo: _price.start)
          .where('price', isLessThanOrEqualTo: _price.end);
    }
    final bool matesNarrowed =
        _mates.start > _matesMin || _mates.end < _matesMax;
    if (matesNarrowed) {
      q = q
          .where('roommates', isGreaterThanOrEqualTo: _mates.start.round())
          .where('roommates', isLessThanOrEqualTo: _mates.end.round());
    }
    switch (_sort) {
      case 'Price ↓':
        q = q.orderBy('price', descending: true);
        break;
      case 'Price ↑':
        q = q.orderBy('price');
        break;
      case 'Oldest first':
        q = q.orderBy('createdAt');
        break;
      default:
        q = q.orderBy('createdAt', descending: true);
    }
    return q;
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();
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
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ExpansionTile(
              title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Row(
                  children: [
                    const Text('Sort by:'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _sort,
                      items: const ['Newest first', 'Oldest first', 'Price ↓', 'Price ↑']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _sort = val ?? _sort),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Location:'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _location,
                      hint: const Text('Any'),
                      items: const ['København', 'Østerbro', 'Kongens Lyngby']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _location = val),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Price range: DKK ${_price.start.toInt()} – ${_price.end.toInt()}'),
                RangeSlider(
                  min: _priceMin,
                  max: _priceMax,
                  divisions: 100,
                  values: _price,
                  labels: RangeLabels(
                    _price.start.toInt().toString(),
                    _price.end.toInt().toString(),
                  ),
                  onChanged: (v) => setState(() => _price = v),
                ),
                const SizedBox(height: 12),
                Text('Room-mates: ${_mates.start.toInt()} – ${_mates.end.toInt()}'),
                RangeSlider(
                  min: _matesMin.toDouble(),
                  max: _matesMax.toDouble(),
                  divisions: 10,
                  values: _mates,
                  labels: RangeLabels(
                    _mates.start.toInt().toString(),
                    _mates.end.toInt().toString(),
                  ),
                  onChanged: (v) => setState(() => _mates = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No apartments match.'));
                }
                final docs = snapshot.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final location = d['location'] ?? 'Ukendt';
                    final price = (d['price'] ?? 0).toDouble();
                    final images = (d['imageUrls'] as List?)?.whereType<String>().toList() ?? [];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MoreInformationScreen(data: d)),
                        );
                      },
                      child: ApartmentCard(
                        location: location,
                        price: price,
                        imageUrl: images.isNotEmpty ? images.first : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
