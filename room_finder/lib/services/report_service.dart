import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<void> report({
    required String targetType,
    required String targetId,
    required String targetOwnerId,
    required String reason,
    String? details,
    Map<String, dynamic>? evidenceSnapshot,
  }) async {
    await _db.collection('reports').add({
      'reporterId': _uid,
      'targetType': targetType,
      'targetId': targetId,
      'targetOwnerId': targetOwnerId,
      'reason': reason,
      'details': (details ?? '').trim(),
      'evidenceSnapshot': evidenceSnapshot ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
      'action': '',
    });
  }
}
