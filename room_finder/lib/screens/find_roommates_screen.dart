// find_roommates_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'settings_screen.dart';

/* ---------------- Apartment card ---------------- */

class ApartmentCard extends StatelessWidget {
  final String city;
  final double price;

  const ApartmentCard({
    super.key,
    required this.city,
    required this.price,
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
            /* Placeholder image space */
            Container(
              color: Colors.grey[200],
              height: 100,
              child: const Center(child: Icon(Icons.image, size: 50)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                city,                                       // København / Østerbro → ok
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'DKK ${price.toStringAsFixed(0)}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Screen with filters ---------------- */

class FindRoommatesScreen extends StatefulWidget {
  const FindRoommatesScreen({super.key});

  @override
  State<FindRoommatesScreen> createState() => _FindRoommatesScreenState();
}

class _FindRoommatesScreenState extends State<FindRoommatesScreen> {
  /* ---------------- Filter state ---------------- */

  String _sort = 'Newest first';
  String? _location; // null = all

  RangeValues _price = const RangeValues(0, 5000);
  RangeValues _mates = const RangeValues(0, 5);

  /* ---------------- Build Firestore query ---------------- */

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('apartments');

    if (_location != null) {
      q = q.where('city', isEqualTo: _location);
    }

    q = q
        .where('price', isGreaterThanOrEqualTo: _price.start)
        .where('price', isLessThanOrEqualTo: _price.end)
        .where('roommates', isGreaterThanOrEqualTo: _mates.start.toInt())
        .where('roommates', isLessThanOrEqualTo: _mates.end.toInt());

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

  /* ---------------- UI ---------------- */

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
          /* ----------- Filters ----------- */
          Card(
            margin: const EdgeInsets.all(16),
            child: ExpansionTile(
              initiallyExpanded: false,
              title: const Text('Filters',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                /* Sort */
                Row(
                  children: [
                    const Text('Sort by:'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _sort,
                      items: const [
                        'Newest first',
                        'Oldest first',
                        'Price ↓',
                        'Price ↑',
                      ].map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _sort = val ?? _sort),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                /* Location */
                Row(
                  children: [
                    const Text('Location:'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _location,
                      hint: const Text('Any'),
                      items: const ['København', 'Østerbro']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _location = val),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                /* Price range */
                Text(
                    'Price range: DKK ${_price.start.toInt()} – ${_price.end.toInt()}'),
                RangeSlider(
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  values: _price,
                  labels: RangeLabels(
                    _price.start.toInt().toString(),
                    _price.end.toInt().toString(),
                  ),
                  onChanged: (v) => setState(() => _price = v),
                ),
                const SizedBox(height: 12),

                /* Roommates range */
                Text('Room-mates: ${_mates.start.toInt()} – ${_mates.end.toInt()}'),
                RangeSlider(
                  min: 0,
                  max: 10,
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

          /* ----------- Results grid ----------- */
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
                    final city = d['city'] ?? 'Unknown';
                    final price = (d['price'] ?? 0).toDouble();
                    return ApartmentCard(city: city, price: price);
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
