import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';          // ← hvis ikke allerede i main.dart
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'mere_information.dart';
import 'settings_screen.dart';

/* ----------------------------------------------------------
 *  Thumbnail-kort for ét værelse / lejlighed
 * --------------------------------------------------------*/
class ApartmentCard extends StatefulWidget {
  final List<String> images;
  final String title;
  final String location;
  final num    price;      // kan være int ELLER double i Firestore
  final double size;
  final String period;
  final int    roommates;

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* -------------------------------------------------- Billeder */
            SizedBox(
              height: 180,
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
                              child: const Center(child: Icon(Icons.photo, size: 40)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                        if (widget.images.length > 1)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_page + 1}/${widget.images.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.photo, size: 50)),
                    ),
            ),

            /* ---------------------------------------- titel + lokation */
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            /* ------------------------------------------------ mini-facts */
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text('${widget.price.round()} kr.', style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  const Text('📏', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text('${widget.size.toStringAsFixed(0)} m²',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  const Text('📆', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.period,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👥', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(widget.roommates.toString(), style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------
 *  DRY helper – ens dropdown-rækker
 * --------------------------------------------------------*/
Row _ddRow<T>({
  required String label,
  required T? value,
  String? hint,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) =>
    Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            hint: hint != null ? Text(hint) : null,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );

/* ----------------------------------------------------------
 *  MAIN SCREEN
 * --------------------------------------------------------*/
class FindRoommatesScreen extends StatefulWidget {
  const FindRoommatesScreen({super.key});

  @override
  State<FindRoommatesScreen> createState() => _FindRoommatesScreenState();
}

class _FindRoommatesScreenState extends State<FindRoommatesScreen> {
  /* ---------------- filtre ---------------- */
  String _sort = 'Nyeste først';
  String? _location;
  String? _period;
  int? _maxAgeDays;

  static const double _priceMin = 0, _priceMax = 10000;
  static const int _matesMin = 0, _matesMax = 10;

  RangeValues _price = RangeValues(_priceMin, _priceMax);
  RangeValues _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  static const _sortChoices = ['Nyeste først', 'Ældst først', 'Pris ↓', 'Pris ↑'];
  static const _locations = ['København', 'Østerbro', 'Kongens Lyngby'];
  static const _periods = ['Ubegrænset', '1-3 måneder', '3-6 måneder', '6-12 måneder'];
  static const Map<int, String> _ageChoices = {
    1: 'Seneste 24 timer',
    3: 'Seneste 3 dage',
    7: 'Seneste uge',
    30: 'Seneste måned',
  };

  /* ---------------- Firestore-query ---------------- */
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('apartments');

    debugPrint('[query] loc=$_location period=$_period age=$_maxAgeDays '
        'price=${_price.start}-${_price.end} mates=${_mates.start}-${_mates.end} sort=$_sort');

    if (_location != null) q = q.where('location', isEqualTo: _location);
    if (_period != null) q = q.where('period', isEqualTo: _period);

    if (_maxAgeDays != null) {
      final ts =
          Timestamp.fromDate(DateTime.now().subtract(Duration(days: _maxAgeDays!)));
      q = q.where('createdAt', isGreaterThanOrEqualTo: ts);
    }

    final priceNeeded = _price.start > _priceMin || _price.end < _priceMax;
    final mateNeeded = _mates.start > _matesMin || _mates.end < _matesMax;

    if (priceNeeded) {
      q = q.where('price',
          isGreaterThanOrEqualTo: _price.start, isLessThanOrEqualTo: _price.end);
    }
    if (mateNeeded) {
      q = q.where('roommates',
          isGreaterThanOrEqualTo: _mates.start.round(),
          isLessThanOrEqualTo: _mates.end.round());
    }

    /* ---- orderBy ---------------------------------------------------- */
    switch (_sort) {
      case 'Pris ↓':
        q = q.orderBy('price', descending: true);
        break;
      case 'Pris ↑':
        q = q.orderBy('price');
        break;
      case 'Ældst først':
        q = q.orderBy('createdAt');
        break;
      default:
        q = q.orderBy('createdAt', descending: true); // Nyeste
    }
    /* Sikrer alle inequality-felter også er i orderBy() */
    if (priceNeeded && !_sort.startsWith('Pris')) q = q.orderBy('price');
    if (mateNeeded) q = q.orderBy('roommates');

    return q;
  }

  /* ----------------------------- UI --------------------- */
  @override
  Widget build(BuildContext context) {
    final queryKey = ValueKey(
      '$_location|$_period|$_maxAgeDays|'
      '${_price.start}-${_price.end}|${_mates.start}-${_mates.end}|$_sort',
    );

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
          /* ---------------- Filter-kort ------------------ */
          Card(
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: const Text('Filtre', style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _ddRow<String>(
                  label: 'Sortér',
                  value: _sort,
                  items: _sortChoices
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _sort = v ?? _sort),
                ),
                const SizedBox(height: 16),
                _ddRow<String>(
                  label: 'Lokation',
                  value: _location,
                  hint: 'Alle',
                  items: _locations
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _location = v),
                ),
                const SizedBox(height: 16),
                _ddRow<String>(
                  label: 'Periode',
                  value: _period,
                  hint: 'Alle',
                  items: _periods
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _period = v),
                ),
                const SizedBox(height: 16),
                _ddRow<int>(
                  label: 'Oprettet',
                  value: _maxAgeDays,
                  hint: 'Alle',
                  items: _ageChoices.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _maxAgeDays = v),
                ),
                const SizedBox(height: 16),

                /* pris-slider */
                Text('Pris: ${_price.start.toInt()} – ${_price.end.toInt()} kr.'),
                RangeSlider(
                  min: _priceMin,
                  max: _priceMax,
                  divisions: 100,
                  labels: RangeLabels(
                    '${_price.start.toInt()} kr.',
                    '${_price.end.toInt()} kr.',
                  ),
                  values: _price,
                  onChanged: (v) => setState(() => _price = v),
                ),
                const SizedBox(height: 16),

                /* roommates-slider */
                Text('Roommates: ${_mates.start.toInt()} – ${_mates.end.toInt()}'),
                RangeSlider(
                  min: _matesMin.toDouble(),
                  max: _matesMax.toDouble(),
                  divisions: 10,
                  labels: RangeLabels(
                    _mates.start.round().toString(),
                    _mates.end.round().toString(),
                  ),
                  values: _mates,
                  onChanged: (v) => setState(() => _mates = v),
                ),
                const SizedBox(height: 8),

                /* nulstil-knap */
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nulstil filtre'),
                    onPressed: () => setState(() {
                      _location = null;
                      _period = null;
                      _maxAgeDays = null;
                      _price = RangeValues(_priceMin, _priceMax);
                      _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());
                    }),
                  ),
                ),
              ],
            ),
          ),

          /* ---------------- resultater ------------------ */
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: queryKey,
              stream: _buildQuery().snapshots(),
              builder: (_, snap) {
                /* ----- fejl / manglende indeks ----- */
                if (snap.hasError) {
                  final err = snap.error;
                  if (err is FirebaseException && err.message != null) {
                    debugPrint('[MISSING-INDEX] ${err.message}');
                  }
                  return Center(child: Text('Firestore-fejl: $err'));
                }
                /* ----------------------------------- */

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('Ingen resultater.'));
                }

                debugPrint('[stream] docs=${snap.data!.docs.length}');

                final docs = snap.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        MaterialPageRoute(
                          builder: (_) => MoreInformationScreen(data: d),
                        ),
                      ),
                      child: ApartmentCard(
                        images:    images,
                        title:     d['title']     ?? '',
                        location:  d['location']  ?? 'Ukendt',
                        price:     d['price']     ?? 0,
                        size:      (d['size']     ?? 0).toDouble(),
                        period:    d['period']    ?? '',
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
