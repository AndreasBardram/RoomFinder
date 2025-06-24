import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'mere_information.dart';
import 'settings_screen.dart';

/* -------------------- Thumbnail card -------------------- */

class ApartmentCard extends StatefulWidget {
  final List<String> images;
  final String title;
  final String location;
  final double price;
  final double size;
  final String period;
  final int roommates;
  const ApartmentCard({
    super.key,
    required this.images,
    required this.title,
    required this.location,
    required this.price,
    required this.size,
    required this.period,
    required this.roommates,
  });

  @override
  State<ApartmentCard> createState() => _ApartmentCardState();
}

class _ApartmentCardState extends State<ApartmentCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final hasImg = widget.images.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* ------------ pictures ------------ */
            SizedBox(
              height: 190,
              width: double.infinity,
              child: hasImg
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: widget.images.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: widget.images[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              child:
                                  const Center(child: Icon(Icons.photo, size: 40)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                        if (widget.images.length > 1)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                '${_page + 1}/${widget.images.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          )
                      ],
                    )
                  : Container(
                      color: Colors.grey[200],
                      child:
                          const Center(child: Icon(Icons.photo, size: 50))),
            ),

            /* ------------ title & location ------------ */
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(
                widget.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),

            /* ------------ mini-facts ------------ */
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.price.toStringAsFixed(0)} kr.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  const Text('📏', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text('${widget.size.toStringAsFixed(0)} m²',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Row(
                children: [
                  const Text('📆', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(widget.period,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                  const Text('👥', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(widget.roommates.toString(),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- Find Roommates screen -------------------- */

class FindRoommatesScreen extends StatefulWidget {
  const FindRoommatesScreen({super.key});
  @override
  State<FindRoommatesScreen> createState() => _FindRoommatesScreenState();
}

class _FindRoommatesScreenState extends State<FindRoommatesScreen> {
  String _sort = 'Nyeste først';
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
    if (_location != null) q = q.where('location', isEqualTo: _location);
    if (_price.start > _priceMin || _price.end < _priceMax) {
      q = q
          .where('price', isGreaterThanOrEqualTo: _price.start)
          .where('price', isLessThanOrEqualTo: _price.end);
    }
    if (_mates.start > _matesMin || _mates.end < _matesMax) {
      q = q
          .where('roommates', isGreaterThanOrEqualTo: _mates.start.round())
          .where('roommates', isLessThanOrEqualTo: _mates.end.round());
    }
    switch (_sort) {
      case 'Pris ↓':
        return q.orderBy('price', descending: true);
      case 'Pris ↑':
        return q.orderBy('price');
      case 'Ældst først':
        return q.orderBy('createdAt');
      default:
        return q.orderBy('createdAt', descending: true);
    }
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
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ExpansionTile(
              title: const Text('Filtre',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Row(
                  children: [
                    const Text('Sortér:'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _sort,
                      items: const ['Nyeste først', 'Ældst først', 'Pris ↓', 'Pris ↑']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _sort = v ?? _sort),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Lokation:'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _location,
                      hint: const Text('Alle'),
                      items: const ['København', 'Østerbro', 'Kongens Lyngby']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _location = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Pris: ${_price.start.toInt()} – ${_price.end.toInt()} kr.'),
                RangeSlider(
                  min: _priceMin,
                  max: _priceMax,
                  divisions: 100,
                  values: _price,
                  onChanged: (v) => setState(() => _price = v),
                ),
                const SizedBox(height: 12),
                Text('Roommates: ${_mates.start.toInt()} – ${_mates.end.toInt()}'),
                RangeSlider(
                  min: _matesMin.toDouble(),
                  max: _matesMax.toDouble(),
                  divisions: 10,
                  values: _mates,
                  onChanged: (v) => setState(() => _mates = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('Ingen resultater.'));
                }
                final docs = snap.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final images =
                        (d['imageUrls'] as List?)?.whereType<String>().toList() ?? [];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MoreInformationScreen(data: d)),
                      ),
                      child: ApartmentCard(
                        images: images,
                        title: d['title'] ?? '',
                        location: d['location'] ?? 'Ukendt',
                        price: (d['price'] ?? 0).toDouble(),
                        size: (d['size'] ?? 0).toDouble(),
                        period: d['period'] ?? '',
                        roommates: (d['roommates'] ?? 0) as int,
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
