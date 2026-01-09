class UgcTextFilter {
  static String? validateText(String text) {
    final t = text.trim();
    if (t.isEmpty) return 'Skriv en besked.';
    if (t.length > 2000) return 'Beskeden er for lang.';

    final urlCount = RegExp(r'(https?:\/\/|www\.)', caseSensitive: false).allMatches(t).length;
    if (urlCount >= 3) return 'For mange links.';

    if (RegExp(r'(.)\1{14,}').hasMatch(t)) return 'For mange gentagelser.';

    final lower = t.toLowerCase();
    const blocked = [
      'porn',
      'nude',
      'nudes',
      'naked',
      'sex',
      'escort',
      'onlyfans',
    ];
    if (blocked.any(lower.contains)) return 'Indholdet kan ikke sendes.';

    return null;
  }
}
