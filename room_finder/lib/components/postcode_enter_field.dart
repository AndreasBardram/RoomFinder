import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

class PostnrField extends StatelessWidget {
  final TextEditingController controller;
  const PostnrField({super.key, required this.controller});

  Future<List<String>> _fetch(String q) async {
    if (q.trim().isEmpty) return [];
    final r = await http.get(
      Uri.https('api.dataforsyningen.dk', '/postnumre/autocomplete', {'q': q}),
    );
    if (r.statusCode != 200) return [];
    final list = (jsonDecode(r.body) as List)
        .map<String>((e) => (e['tekst'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Uses InputDecorationTheme from the page (filled, radius 12, padding 14, hintStyle, etc.)
    // so it looks identical to your Title/Adresse fields.
    return TypeAheadField<String>(
      controller: controller,
      suggestionsCallback: _fetch,
      hideOnEmpty: true,
      hideOnError: true,
      // Text field styled by the page theme
      builder: (context, c, f) => TextField(
        controller: c,
        focusNode: f,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'fx 2200 København N',
          // no border/fill here; comes from InputDecorationTheme
        ),
      ),
      // Suggestion item looks clean and compact
      itemBuilder: (_, s) => ListTile(
        dense: true,
        title: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      onSelected: (s) => controller.text = s,
      // Rounded suggestions dropdown like your cards/inputs
      decorationBuilder: (_, child) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
      // Optional: small “no results” state (keeps style tidy)
      emptyBuilder: (_) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Ingen resultater', style: TextStyle(color: Colors.black54)),
      ),
      // Optional: small error state
      errorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Kunne ikke hente forslag', style: TextStyle(color: Colors.black54)),
      ),
    );
  }
}
