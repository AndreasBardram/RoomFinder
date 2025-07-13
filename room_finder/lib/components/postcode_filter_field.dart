import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'custom_styles.dart';

class PostcodeFilterField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String?> onSelected;
  const PostcodeFilterField({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  Future<List<String>> _fetch(String q) async {
    if (q.isEmpty) return [];
    final r = await http.get(
      Uri.https('api.dataforsyningen.dk', '/postnumre/autocomplete', {'q': q}),
    );
    if (r.statusCode != 200) return [];
    return (jsonDecode(r.body) as List)
        .map<String>((e) => e['tekst'] as String)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      controller: controller,
      suggestionsCallback: _fetch,
      hideOnEmpty: true,
      hideOnError: true,
      builder: (context, c, f) => TextField(
        controller: c,
        focusNode: f,
        decoration: customInputDecoration(labelText: 'Lokation').copyWith(
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              controller.clear();
              onSelected(null);
            },
          ),
        ),
        keyboardType: TextInputType.number,
      ),
      itemBuilder: (_, s) => ListTile(title: Text(s)),
      onSelected: onSelected,
      decorationBuilder: (_, child) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}
