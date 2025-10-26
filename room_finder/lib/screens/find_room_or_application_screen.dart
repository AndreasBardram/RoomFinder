import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'more_information_apartment.dart';
import 'settings_screen.dart';
import '../components/postcode_filter_field.dart';
import '../components/custom_styles.dart';
import 'more_information_application.dart';
import '../components/no_transition.dart'; // ← use shared no-transition helpers

class FindRoommatesScreen extends StatefulWidget {
  const FindRoommatesScreen({super.key});
  @override
  State<FindRoommatesScreen> createState() => _FindRoommatesScreenState();
}

class _FindRoommatesScreenState extends State<FindRoommatesScreen> {
  final _locCtl = TextEditingController();
  final _scroll = ScrollController();

  String _sort = 'Nyeste først';
  String? _location;
  String? _period;
  int? _maxAgeDays;

  // Shared money range (used as "Pris" for apartments, "Budget" for applications)
  static const double _moneyMin = 0, _moneyMax = 10000;
  static const double _sizeMin = 0, _sizeMax = 200;
  static const int _matesMin = 0, _matesMax = 10;

  // Reuse this for price or budget depending on mode
  RangeValues _money = const RangeValues(_moneyMin, _moneyMax);
  RangeValues _size = const RangeValues(_sizeMin, _sizeMax);
  RangeValues _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  static const _periods = ['Ubegrænset', '1-3 måneder', '3-6 måneder', '6-12 måneder'];
  static const Map<int, String> _ageChoices = {1: 'Seneste 24 timer', 3: 'Seneste 3 dage', 7: 'Seneste uge', 30: 'Seneste måned'};

  String _appliedSort = 'Nyeste først';
  String? _appliedLocation;
  String? _appliedPeriod;
  int? _appliedMaxAgeDays;
  RangeValues _appliedMoney = const RangeValues(_moneyMin, _moneyMax);
  RangeValues _appliedSize = const RangeValues(_sizeMin, _sizeMax);
  RangeValues _appliedMates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  bool _filtersOpen = false;
  String? _profileType;

  static const _labelColor = Color(0xFF374151);
  static const _iconColor = Color(0xFF4B5563);
  static const _fill = Color(0xFFF3F4F6);
  static const _btnBg = Color(0xFF111827);
  static const _trackActive = Colors.black;
  static const _trackInactive = Color(0xFFB0B6BF);
  static const double _controlH = 44;

  static const TextStyle _subMuted = TextStyle(fontSize: 14, color: Colors.black54);
  static const TextStyle _subStrong = TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600);
  static const TextStyle _titleStrong = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

  static const int _pageSize = 10;
  static const int _maxFetchRounds = 6;
  bool _initialLoading = true;
  bool _pageLoading = false;
  bool _hasMore = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  // Cache image futures so expanding/collapsing filters doesn't trigger refetches
  final Map<String, Future<List<String>>> _imageFutureCache = {};

  @override
  void initState() {
    super.initState();
    _loadProfileType();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageLoading || !_hasMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _fetchNext();
    }
  }

  Future<void> _loadProfileType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = snap.data() ?? {};
      final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
      _profileType = (meta['profileType'] ?? '').toString();
    }
    await _reload();
  }

  @override
  void dispose() {
    _locCtl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _isSeeker => (_profileType ?? '').toLowerCase() != 'landlord';

  // Sort choices differ by mode:
  List<String> get _sortChoices => _isSeeker
      ? const ['Nyeste først', 'Ældst først', 'Pris ↓', 'Pris ↑', 'Størrelse ↓', 'Størrelse ↑']
      : const ['Nyeste først', 'Ældst først', 'Budget ↓', 'Budget ↑'];

  Query<Map<String, dynamic>> _baseQuery() {
    // seekers browse apartments; landlords browse applications
    final coll = _isSeeker ? 'apartments' : 'applications';
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection(coll);

    if (_isSeeker) {
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
    } else {
      // landlord looking at applications: only budget & date sorts
      switch (_appliedSort) {
        case 'Budget ↓':
          q = q.orderBy('budget', descending: true);
          break;
        case 'Budget ↑':
          q = q.orderBy('budget');
          break;
        case 'Ældst først':
          q = q.orderBy('createdAt');
          break;
        default:
          q = q.orderBy('createdAt', descending: true);
      }
    }

    return q;
  }

  bool _passesClientFilters(Map<String, dynamic> d) {
    if (_isSeeker) {
      // apartments: all filters
      if (_appliedLocation != null && (d['location'] ?? '') != _appliedLocation) return false;
      if (_appliedPeriod != null && (d['period'] ?? '') != _appliedPeriod) return false;
      if (_appliedMaxAgeDays != null) {
        final ts = (d['createdAt'] as Timestamp?)?.toDate();
        if (ts == null || ts.isBefore(DateTime.now().subtract(Duration(days: _appliedMaxAgeDays!)))) {
          return false;
        }
      }
      final p = ((d['price'] ?? 0) as num).toDouble();
      final s = ((d['size'] ?? 0) as num).toDouble();
      final m = ((d['roommates'] ?? 0) as num).toDouble();
      final moneyOk = p >= _appliedMoney.start && p <= _appliedMoney.end;
      final sizeOk = s >= _appliedSize.start && s <= _appliedSize.end;
      final matesOk = m >= _appliedMates.start && m <= _appliedMates.end;
      if (!moneyOk || !sizeOk || !matesOk) return false;
      return true;
    } else {
      // applications: only budget range filter
      final b = ((d['budget'] ?? 0) as num).toDouble();
      final budgetOk = b >= _appliedMoney.start && b <= _appliedMoney.end;
      return budgetOk;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _initialLoading = true;
      _pageLoading = false;
      _hasMore = true;
      _docs = [];
      _lastDoc = null;
      // keep image cache
      // Ensure current sort is valid for current mode
      if (!_sortChoices.contains(_sort)) _sort = 'Nyeste først';
    });
    await _fetchNext();
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _fetchNext() async {
    if (!_hasMore) return;
    setState(() => _pageLoading = true);
    try {
      var q = _baseQuery();
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);

      int collected = 0;
      int rounds = 0;
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> accepted = [];

      while (collected < _pageSize && _hasMore && rounds < _maxFetchRounds) {
        final snap = await q.limit(_pageSize).get();
        if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
        final filtered = snap.docs.where((d) => _passesClientFilters(d.data())).toList();
        accepted.addAll(filtered);
        collected += filtered.length;
        if (snap.docs.length < _pageSize) {
          _hasMore = false;
          break;
        }
        q = _baseQuery().startAfterDocument(_lastDoc!);
        rounds++;
      }

      if (accepted.isNotEmpty) _docs.addAll(accepted);
    } finally {
      if (mounted) setState(() => _pageLoading = false);
    }
  }

  void _applyFilters() {
    _appliedSort = _sort;

    if (_isSeeker) {
      _appliedLocation = _location;
      _appliedPeriod = _period;
      _appliedMaxAgeDays = _maxAgeDays;
      _appliedMoney = _money; // price
      _appliedSize = _size;
      _appliedMates = _mates;
    } else {
      // applications: only budget
      _appliedMoney = _money; // budget
      // Clear other applied filters to avoid confusion
      _appliedLocation = null;
      _appliedPeriod = null;
      _appliedMaxAgeDays = null;
      _appliedSize = const RangeValues(_sizeMin, _sizeMax);
      _appliedMates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());
    }
    _reload();
  }

  Future<List<String>> _fetchImageUrls(String parentCollection, String parentId) async {
    final q = await FirebaseFirestore.instance
        .collection('images')
        .where('parentCollection', isEqualTo: parentCollection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('index')
        .limit(6)
        .get();
    return q.docs.map((d) => (d.data()['url'] as String)).toList();
  }

  Future<List<String>> _fetchAndPrefetchImages(String parentCollection, String parentId) async {
    final urls = await _fetchImageUrls(parentCollection, parentId);
    if (urls.isNotEmpty) {
      await Future.wait(urls.map((u) => precacheImage(NetworkImage(u), context)));
    }
    return urls;
  }

  // Return a cached future for images to avoid refetching on rebuild
  Future<List<String>> _imageFutureFor(String parentCollection, String parentId) {
    final key = '$parentCollection/$parentId';
    return _imageFutureCache.putIfAbsent(key, () => _fetchAndPrefetchImages(parentCollection, parentId));
  }

  @override
  Widget build(BuildContext context) {
    final isSeeker = _isSeeker;
    final themed = Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
        selectionColor: Color(0x33000000),
        selectionHandleColor: Colors.black,
      ),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          title: Text(isSeeker ? 'Find værelser' : 'Se ansøgninger'),
          actions: [
            IconButton(
              icon: const Icon(FluentIcons.settings_24_regular),
              onPressed: () => pushNoAnim(context, const SettingsScreen()), // ← no transition
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: 1 + (_initialLoading ? 5 : _docs.length + (_pageLoading ? 1 : 0)),
            itemBuilder: (_, i) {
              if (i == 0) return _buildFilterCard(context, isSeeker);

              if (_initialLoading) return const _SkeletonCard();

              final index = i - 1;
              if (index >= _docs.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final doc = _docs[index];
              final d = doc.data();

              if (isSeeker) {
                // apartments cards
                return FutureBuilder<List<String>>(
                  future: _imageFutureFor('apartments', doc.id),
                  builder: (ctx, imgSnap) {
                    final waiting = imgSnap.connectionState == ConnectionState.waiting && (imgSnap.data == null);
                    final images = imgSnap.data ?? const <String>[];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: waiting
                                  ? const _SkeletonImage()
                                  : GestureDetector(
                                      onTap: () => pushNoAnim( // ← no transition
                                        context,
                                        MoreInformationScreen(
                                          data: d,
                                          parentCollection: 'apartments',
                                          parentId: doc.id,
                                        ),
                                      ),
                                      child: _UrlImagesPager(urls: images),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: _titleStrong),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(child: Text(d['location'] ?? 'Ukendt', maxLines: 1, overflow: TextOverflow.ellipsis, style: _subMuted)),
                                    Text('${(d['size'] ?? 0).toString()} m²', style: _subMuted),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(children: [Expanded(child: Text('Periode: ${d['period'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: _subMuted))]),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: Text('Roommates: ${((d['roommates'] ?? 0) as num).toInt()}', style: _subMuted)),
                                    Text('${(d['price'] ?? 0).toString()} DKK', style: _subStrong),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                // applications cards
                return FutureBuilder<List<String>>(
                  future: _imageFutureFor('applications', doc.id),
                  builder: (ctx, imgSnap) {
                    final waiting = imgSnap.connectionState == ConnectionState.waiting && (imgSnap.data == null);
                    final images = imgSnap.data ?? const <String>[];
                    final budget = (d['budget'] ?? 0).toString();
                    return InkWell(
                      onTap: () => pushNoAnim( // ← no transition
                        context,
                        MoreInformationApplicationScreen(
                          data: d,
                          parentCollection: 'applications',
                          parentId: doc.id,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: waiting ? const _SkeletonImage() : _UrlImagesPager(urls: images),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: _titleStrong),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(child: Text((d['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: _subMuted)),
                                      const SizedBox(width: 8),
                                      Text('$budget DKK', style: _subStrong),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, bool isSeeker) {
    // seekers: full filters; landlords: only Sort + Budget
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _filtersOpen = !_filtersOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 18, color: _iconColor),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Filtre', style: TextStyle(color: _labelColor, fontWeight: FontWeight.w600))),
                  AnimatedRotation(
                    turns: _filtersOpen ? .5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(PhosphorIcons.caretDown(), color: _iconColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (_filtersOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Sort
                  _rowLabel(
                    'Sortér',
                    _sizedField(
                      _ddForm<String>(
                        context,
                        value: _sort,
                        items: _sortChoices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _sort = v ?? _sort),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Budget/Price slider (always visible but labeled appropriately)
                  _info(isSeeker ? 'Pris' : 'Budget',
                      '${_money.start.toInt()}–${_money.end.toInt()} kr.'),
                  _sliderTheme(
                    context,
                    RangeSlider(
                      min: _moneyMin,
                      max: _moneyMax,
                      divisions: 100,
                      values: _money,
                      onChanged: (v) => setState(() => _money = v),
                    ),
                  ),

                  if (isSeeker) ...[
                    const SizedBox(height: 12),
                    // Location
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
                    // Period
                    _rowLabel(
                      'Periode',
                      _sizedField(
                        _ddForm<String?>(
                          context,
                          value: _period,
                          hint: const Text('Alle'),
                          items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) => setState(() => _period = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Created
                    _rowLabel(
                      'Oprettet',
                      _sizedField(
                        _ddForm<int?>(
                          context,
                          value: _maxAgeDays,
                          hint: const Text('Alle'),
                          items: _ageChoices.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) => setState(() => _maxAgeDays = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Size
                    _info('Størrelse', '${_size.start.toInt()}–${_size.end.toInt()} m²'),
                    _sliderTheme(
                      context,
                      RangeSlider(
                        min: _sizeMin,
                        max: _sizeMax,
                        divisions: 40,
                        values: _size,
                        onChanged: (v) => setState(() => _size = v),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Roommates
                    _info('Roommates', '${_mates.start.toInt()}–${_mates.end.toInt()}'),
                    _sliderTheme(
                      context,
                      RangeSlider(
                        min: _matesMin.toDouble(),
                        max: _matesMax.toDouble(),
                        divisions: 10,
                        values: _mates,
                        onChanged: (v) => setState(() => _mates = v),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: _controlH,
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(const Color(0xFFEFF2F6)),
                              minimumSize: MaterialStateProperty.all(const Size(double.infinity, _controlH)),
                              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                              foregroundColor: MaterialStateProperty.all(_labelColor),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                            onPressed: () => setState(() {
                              _sort = 'Nyeste først';
                              _money = const RangeValues(_moneyMin, _moneyMax);
                              if (isSeeker) {
                                _locCtl.clear();
                                _location = null;
                                _period = null;
                                _maxAgeDays = null;
                                _size = const RangeValues(_sizeMin, _sizeMax);
                                _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());
                              }
                            }),
                            child: const Text('Nulstil filtre'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: _controlH,
                          child: CustomButtonContainer(
                            child: ElevatedButton(
                              style: customElevatedButtonStyle().copyWith(
                                minimumSize: MaterialStateProperty.all(const Size(double.infinity, _controlH)),
                                padding: MaterialStateProperty.all(EdgeInsets.zero),
                                backgroundColor: MaterialStateProperty.all(_btnBg),
                                foregroundColor: MaterialStateProperty.all(Colors.white),
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                              onPressed: _applyFilters,
                              child: const Text('Opdater'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
  Widget _label(String l) => SizedBox(width: 90, child: Text(l, style: const TextStyle(color: _labelColor)));
  Widget _info(String l, String v) => Row(children: [Icon(PhosphorIcons.info(), size: 16, color: _iconColor), const SizedBox(width: 6), Text('$l: $v', style: const TextStyle(color: _labelColor))]);

  Widget _sliderTheme(BuildContext context, Widget child) {
    final base = SliderTheme.of(context);
    return SliderTheme(
      data: base.copyWith(
        trackHeight: 6,
        activeTrackColor: _trackActive,
        inactiveTrackColor: _trackInactive,
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: SliderComponentShape.noOverlay,
        thumbColor: Colors.white,
        valueIndicatorColor: Colors.grey,
      ),
      child: child,
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
    if (len == 0) {
      return const _SkeletonImage();
    }
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

// Small nav button
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
    return const _Shimmer(child: ColoredBox(color: Color(0xFFEFF2F6)));
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 16 / 9, child: _SkeletonImage()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Shimmer(child: _Box(width: 200, height: 16)),
                SizedBox(height: 10),
                _Shimmer(child: _Box(width: 160, height: 12)),
                SizedBox(height: 6),
                _Shimmer(child: _Box(width: 120, height: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final double width;
  final double height;
  const _Box({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFEFF2F6), borderRadius: BorderRadius.circular(6)),
    );
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
      builder: (_, child) {
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
