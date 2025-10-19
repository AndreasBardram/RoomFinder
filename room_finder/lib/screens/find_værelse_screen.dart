import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../components/apartment_card.dart';
import 'mere_information.dart';
import 'settings_screen.dart';
import '../components/postcode_filter_field.dart';
import '../components/custom_styles.dart';

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

  bool _filtersOpen = true;

  static const _labelColor = Color(0xFF374151);
  static const _iconColor = Color(0xFF4B5563);
  static const _fill = Color(0xFFF3F4F6);
  static const _btnBg = Color(0xFF111827);
  static const _trackActive = Colors.black87;
  static const _trackInactive = Colors.black45;

  static const double _controlH = 44;

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
    if (priceNeeded) {
      q = q.where('price', isGreaterThanOrEqualTo: _appliedPrice.start, isLessThanOrEqualTo: _appliedPrice.end);
    }
    if (sizeNeeded) {
      q = q.where('size', isGreaterThanOrEqualTo: _appliedSize.start, isLessThanOrEqualTo: _appliedSize.end);
    }
    if (mateNeeded) {
      q = q.where('roommates', isGreaterThanOrEqualTo: _appliedMates.start.round(), isLessThanOrEqualTo: _appliedMates.end.round());
    }
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
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.gearSix(), color: _iconColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterCard(context),
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

  Widget _buildFilterCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _filtersOpen = !_filtersOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Expanded(child: Text('Filtre', style: TextStyle(color: _labelColor))),
                  Icon(PhosphorIcons.slidersHorizontal(), color: _iconColor, size: 20),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _filtersOpen ? .5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(PhosphorIcons.caretDown(), color: _iconColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            crossFadeState: _filtersOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 150),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _rowLabel('Sortér', _sizedField(_ddForm<String>(
                    context,
                    value: _sort,
                    items: _sortChoices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _sort = v ?? _sort),
                  ))),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _label('Lokation'),
                      Expanded(
                        child: SizedBox(
                          height: _controlH,
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Container(
                                height: _controlH,
                                decoration: BoxDecoration(color: _fill, borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.only(left: 12, right: 36),
                                child: Center(
                                  child: PostcodeFilterField(
                                    controller: _locCtl,
                                    onSelected: (s) => setState(() {
                                      _location = s;
                                      _locCtl.text = s ?? '';
                                    }),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(PhosphorIcons.caretDown(), size: 18, color: _iconColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _rowLabel('Periode', _sizedField(_ddForm<String?>(
                    context,
                    value: _period,
                    hint: const Text('Alle'),
                    items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _period = v),
                  ))),
                  const SizedBox(height: 12),
                  _rowLabel('Oprettet', _sizedField(_ddForm<int?>(
                    context,
                    value: _maxAgeDays,
                    hint: const Text('Alle'),
                    items: _ageChoices.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setState(() => _maxAgeDays = v),
                  ))),
                  const SizedBox(height: 12),
                  _info('Pris', '${_price.start.toInt()}–${_price.end.toInt()} kr.'),
                  _sliderTheme(context, RangeSlider(
                    min: _priceMin,
                    max: _priceMax,
                    divisions: 100,
                    values: _price,
                    onChanged: (v) => setState(() => _price = v),
                  )),
                  const SizedBox(height: 8),
                  _info('Størrelse', '${_size.start.toInt()}–${_size.end.toInt()} m²'),
                  _sliderTheme(context, RangeSlider(
                    min: _sizeMin,
                    max: _sizeMax,
                    divisions: 40,
                    values: _size,
                    onChanged: (v) => setState(() => _size = v),
                  )),
                  const SizedBox(height: 8),
                  _info('Roommates', '${_mates.start.toInt()}–${_mates.end.toInt()}'),
                  _sliderTheme(context, RangeSlider(
                    min: _matesMin.toDouble(),
                    max: _matesMax.toDouble(),
                    divisions: 10,
                    values: _mates,
                    onChanged: (v) => setState(() => _mates = v),
                  )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        height: _controlH,
                        child: TextButton(
                          style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(const Size(0, _controlH)),
                            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                            foregroundColor: MaterialStateProperty.all(_labelColor),
                          ),
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
                          child: const Text('Nulstil filtre'),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 200,
                        height: _controlH,
                        child: CustomButtonContainer(
                          child: ElevatedButton(
                            style: customElevatedButtonStyle().copyWith(
                              minimumSize: MaterialStateProperty.all(const Size(double.infinity, _controlH)),
                              padding: MaterialStateProperty.all(EdgeInsets.zero),
                              backgroundColor: MaterialStateProperty.all(_btnBg),
                              foregroundColor: MaterialStateProperty.all(Colors.white),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
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
        ],
      ),
    );
  }

  Widget _ddForm<T>(
    BuildContext context, {
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    T? value,
    Widget? hint,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      icon: Icon(PhosphorIcons.caretDown(), size: 18, color: _iconColor),
      decoration: const InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _fill,
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: hint,
    );
  }

  Widget _sizedField(Widget child) => SizedBox(height: _controlH, child: Center(child: child));
  Widget _rowLabel(String l, Widget w) => Row(children: [_label(l), Expanded(child: w)]);
  Widget _label(String l) => SizedBox(width: 80, child: Text(l, style: const TextStyle(color: _labelColor)));
  Widget _info(String l, String v) => Row(children: [Icon(PhosphorIcons.info(), size: 16, color: _iconColor), const SizedBox(width: 6), Text('$l: $v', style: const TextStyle(color: _labelColor))]);

  Widget _sliderTheme(BuildContext context, Widget child) {
    final base = SliderTheme.of(context);
    return SliderTheme(
      data: base.copyWith(
        trackHeight: 8,
        activeTrackColor: _trackActive,
        inactiveTrackColor: _trackInactive,
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: SliderComponentShape.noOverlay,
        thumbColor: Colors.white,
        valueIndicatorColor: Colors.grey,
      ),
      child: child,
    );
  }
}
