import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../components/apartment_card.dart';
import 'mere_information.dart';
import 'settings_screen.dart';
import '../components/postcode_filter_field.dart';
import '../components/custom_styles.dart';

Row _ddRow<T>({
  required String label,
  required T? value,
  String? hint,
  bool allowNull = false,
  String nullLabel = 'Alle',
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  IconData? phosphorIcon,
}) {
  final fullItems = allowNull ? [DropdownMenuItem<T>(value: null, child: Text(nullLabel))] + items : items;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(width: 80, child: Text(label)),
      Expanded(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: hint != null ? Text(hint) : null,
          items: fullItems,
          onChanged: onChanged,
          icon: Icon(phosphorIcon ?? PhosphorIcons.caretDown(), size: 18, color: Colors.grey[700]),
        ),
      ),
    ],
  );
}

class FindRoommatesScreen extends StatefulWidget {
  const FindRoommatesScreen({super.key});
  @override
  State<FindRoommatesScreen> createState() => _FindRoommatesScreenState();
}

class _FindRoommatesScreenState extends State<FindRoommatesScreen> {
  final _locCtl = TextEditingController();

  String _sort = 'Nyeste først';
  String? _location;
  String? _period;
  int? _maxAgeDays;

  static const double _priceMin = 0, _priceMax = 10000;
  static const double _sizeMin = 0, _sizeMax = 200;
  static const int _matesMin = 0, _matesMax = 10;

  RangeValues _price = const RangeValues(_priceMin, _priceMax);
  RangeValues _size = const RangeValues(_sizeMin, _sizeMax);
  RangeValues _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  static const _sortChoices = ['Nyeste først', 'Ældst først', 'Pris ↓', 'Pris ↑', 'Størrelse ↓', 'Størrelse ↑'];
  static const _periods = ['Ubegrænset', '1-3 måneder', '3-6 måneder', '6-12 måneder'];
  static const Map<int, String> _ageChoices = {1: 'Seneste 24 timer', 3: 'Seneste 3 dage', 7: 'Seneste uge', 30: 'Seneste måned'};

  String _appliedSort = 'Nyeste først';
  String? _appliedLocation;
  String? _appliedPeriod;
  int? _appliedMaxAgeDays;
  RangeValues _appliedPrice = const RangeValues(_priceMin, _priceMax);
  RangeValues _appliedSize = const RangeValues(_sizeMin, _sizeMax);
  RangeValues _appliedMates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  Stream<QuerySnapshot<Map<String, dynamic>>>? _resultsStream;

  @override
  void initState() {
    super.initState();
    _resultsStream = _buildAppliedQuery().snapshots();
  }

  @override
  void dispose() {
    _locCtl.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _buildAppliedQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('apartments');
    if (_appliedLocation != null) q = q.where('location', isEqualTo: _appliedLocation);
    if (_appliedPeriod != null) q = q.where('period', isEqualTo: _appliedPeriod);
    if (_appliedMaxAgeDays != null) {
      final ts = Timestamp.fromDate(DateTime.now().subtract(Duration(days: _appliedMaxAgeDays!)));
      q = q.where('createdAt', isGreaterThanOrEqualTo: ts);
    }
    final priceNeeded = _appliedPrice.start > _priceMin || _appliedPrice.end < _priceMax;
    final sizeNeeded = _appliedSize.start > _sizeMin || _appliedSize.end < _sizeMax;
    final mateNeeded = _appliedMates.start > _matesMin || _appliedMates.end < _matesMax;
    if (priceNeeded) q = q.where('price', isGreaterThanOrEqualTo: _appliedPrice.start, isLessThanOrEqualTo: _appliedPrice.end);
    if (sizeNeeded) q = q.where('size', isGreaterThanOrEqualTo: _appliedSize.start, isLessThanOrEqualTo: _appliedSize.end);
    if (mateNeeded) q = q.where('roommates', isGreaterThanOrEqualTo: _appliedMates.start.round(), isLessThanOrEqualTo: _appliedMates.end.round());
    switch (_appliedSort) {
      case 'Pris ↓':
        q = q.orderBy('price', descending: true);
        break;
      case 'Pris ↑':
        q = q.orderBy('price');
        break;
      case 'Størrelse ↓':
        q = q.orderBy('size', descending: true);
        break;
      case 'Størrelse ↑':
        q = q.orderBy('size');
        break;
      case 'Ældst først':
        q = q.orderBy('createdAt');
        break;
      default:
        q = q.orderBy('createdAt', descending: true);
    }
    if (priceNeeded && !_appliedSort.startsWith('Pris')) q = q.orderBy('price');
    if (sizeNeeded && !_appliedSort.startsWith('Størrelse')) q = q.orderBy('size');
    if (mateNeeded) q = q.orderBy('roommates');
    return q;
  }

  void _applyFilters() {
    _appliedSort = _sort;
    _appliedLocation = _location;
    _appliedPeriod = _period;
    _appliedMaxAgeDays = _maxAgeDays;
    _appliedPrice = _price;
    _appliedSize = _size;
    _appliedMates = _mates;
    _resultsStream = _buildAppliedQuery().snapshots();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Roommates'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.gearSix()),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('Filtre', style: TextStyle(fontWeight: FontWeight.normal)),
                trailing: Icon(PhosphorIcons.slidersHorizontal(), color: Colors.grey[700], size: 22),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _ddRow<String>(
                    label: 'Sortér',
                    value: _sort,
                    items: _sortChoices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _sort = v ?? _sort),
                    phosphorIcon: PhosphorIcons.sortAscending(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 80, child: Text('Lokation')),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            PostcodeFilterField(
                              controller: _locCtl,
                              onSelected: (s) => setState(() => _location = s),
                            ),
                            Icon(PhosphorIcons.caretDown(), size: 18, color: Colors.grey[700]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ddRow<String?>(
                    label: 'Periode',
                    value: _period,
                    allowNull: true,
                    items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _period = v),
                    phosphorIcon: PhosphorIcons.calendar(),
                  ),
                  const SizedBox(height: 16),
                  _ddRow<int?>(
                    label: 'Oprettet',
                    value: _maxAgeDays,
                    allowNull: true,
                    items: _ageChoices.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setState(() => _maxAgeDays = v),
                    phosphorIcon: PhosphorIcons.clock(),
                  ),
                  const SizedBox(height: 16),
                  _buildSliderWithIcon(PhosphorIcons.currencyDollarSimple(), 'Pris', '${_price.start.toInt()} – ${_price.end.toInt()} kr.'),
                  RangeSlider(
                    min: _priceMin,
                    max: _priceMax,
                    divisions: 100,
                    labels: RangeLabels('${_price.start.toInt()} kr.', '${_price.end.toInt()} kr.'),
                    values: _price,
                    onChanged: (v) => setState(() => _price = v),
                  ),
                  const SizedBox(height: 16),
                  _buildSliderWithIcon(PhosphorIcons.ruler(), 'Størrelse', '${_size.start.toInt()} – ${_size.end.toInt()} m²'),
                  RangeSlider(
                    min: _sizeMin,
                    max: _sizeMax,
                    divisions: 40,
                    labels: RangeLabels('${_size.start.toInt()} m²', '${_size.end.toInt()} m²'),
                    values: _size,
                    onChanged: (v) => setState(() => _size = v),
                  ),
                  const SizedBox(height: 16),
                  _buildSliderWithIcon(PhosphorIcons.users(), 'Roommates', '${_mates.start.toInt()} – ${_mates.end.toInt()}'),
                  RangeSlider(
                    min: _matesMin.toDouble(),
                    max: _matesMax.toDouble(),
                    divisions: 10,
                    labels: RangeLabels(_mates.start.round().toString(), _mates.end.round().toString()),
                    values: _mates,
                    onChanged: (v) => setState(() => _mates = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: Icon(PhosphorIcons.arrowCounterClockwise()),
                        label: const Text('Nulstil filtre'),
                        onPressed: () => setState(() {
                          _locCtl.clear();
                          _location = null;
                          _period = null;
                          _maxAgeDays = null;
                          _price = const RangeValues(_priceMin, _priceMax);
                          _size = const RangeValues(_sizeMin, _sizeMax);
                          _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());
                          _sort = 'Nyeste først';
                        }),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 200,
                        child: CustomButtonContainer(
                          child: ElevatedButton(
                            style: customElevatedButtonStyle(),
                            onPressed: _applyFilters,
                            child: const Text('Opdater'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _resultsStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _resultsStream,
                    builder: (_, snap) {
                      if (snap.hasError) return Center(child: Text('Firestore-fejl: ${snap.error}'));
                      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('Ingen resultater.'));
                      final docs = snap.data!.docs;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          const count = 2;
                          const hPad = 16.0;
                          const spacing = 16.0;
                          final w = (constraints.maxWidth - hPad * 2 - spacing * (count - 1)) / count;
                          final h = w * 9 / 16 + 210;
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              return GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MoreInformationScreen(data: d))),
                                child: ApartmentCard(
                                  images: images,
                                  title: d['title'] ?? '',
                                  location: d['location'] ?? 'Ukendt',
                                  price: d['price'] ?? 0,
                                  size: (d['size'] ?? 0).toDouble(),
                                  period: d['period'] ?? '',
                                  roommates: (d['roommates'] ?? 0) as int,
                                ),
                              );
                            },
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

  Widget _buildSliderWithIcon(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text('$label: $value', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
