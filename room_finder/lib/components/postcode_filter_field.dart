import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

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
      controller: controller,                 // external controller
      suggestionsCallback: _fetch,
      hideOnEmpty: true,
      hideOnError: true,
      // use the SAME controller so the text updates visibly
      builder: (context, _ignored, focus) => TextField(
        controller: controller,
        focusNode: focus,
        decoration: const InputDecoration.collapsed(hintText: 'Alle'),
      ),
      itemBuilder: (_, s) => ListTile(title: Text(s)),
      onSelected: (s) {
        controller.text = s;        
        onSelected(s);                
      },
      decorationBuilder: (_, child) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}
