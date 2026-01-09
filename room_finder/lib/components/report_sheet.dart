import 'package:flutter/material.dart';

class ReportResult {
  final String reason;
  final String details;
  ReportResult({required this.reason, required this.details});
}

Future<ReportResult?> showReportSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  final details = TextEditingController();

  const reasons = <(String, String)>[
    ('spam', 'Spam'),
    ('harassment', 'Chikane'),
    ('sexual', 'Seksuelt indhold'),
    ('hate', 'Had/krænkende'),
    ('violence', 'Vold/trusler'),
    ('other', 'Andet'),
  ];

  String selected = reasons.first.$1;

  return showModalBottomSheet<ReportResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;

      return StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.grey, height: 1.3)),
              ],
              const SizedBox(height: 14),
              const Text('Årsag', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final r in reasons)
                RadioListTile<String>(
                  value: r.$1,
                  groupValue: selected,
                  onChanged: (v) => setSheetState(() => selected = v!),
                  title: Text(r.$2),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                ),
              const SizedBox(height: 10),
              TextField(
                controller: details,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tilføj evt. detaljer (valgfrit)',
                  filled: true,
                  fillColor: const Color(0xFFF6F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.pop(
                  ctx,
                  ReportResult(reason: selected, details: details.text.trim()),
                ),
                child: const Text('Send rapport'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: Color(0xFFE6E8EF), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuller'),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(details.dispose);
}
