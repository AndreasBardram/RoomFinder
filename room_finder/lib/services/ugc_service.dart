import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomModerationState {
  final bool isBlocked;
  final String? blockedBy;
  final String? blockedUserId;

  const RoomModerationState({
    required this.isBlocked,
    required this.blockedBy,
    required this.blockedUserId,
  });
}

class UgcService {
  UgcService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<RoomModerationState> roomModerationState(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((snap) {
      final d = snap.data() ?? {};
      return RoomModerationState(
        isBlocked: (d['isBlocked'] ?? false) == true,
        blockedBy: d['blockedBy']?.toString(),
        blockedUserId: d['blockedUserId']?.toString(),
      );
    });
  }

  Future<void> blockRoom({
    required String roomId,
    required String blockedUserId,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('rooms').doc(roomId).update({
      'isBlocked': true,
      'blockedBy': uid,
      'blockedUserId': blockedUserId,
      'blockedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockRoom({required String roomId}) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('rooms').doc(roomId).update({
      'isBlocked': false,
      'blockedBy': FieldValue.delete(),
      'blockedUserId': FieldValue.delete(),
      'blockedAt': FieldValue.delete(),
      'unblockedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportUser({
    required String roomId,
    required String reportedUserId,
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('reports').add({
      'type': 'user',
      'reporterId': uid,
      'reportedUserId': reportedUserId,
      'roomId': roomId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportMessage({
    required String roomId,
    required String messageId,
    required String messageAuthorId,
    required String reason,
    String? textSnippet,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('reports').add({
      'type': 'message',
      'reporterId': uid,
      'reportedUserId': messageAuthorId,
      'roomId': roomId,
      'messageId': messageId,
      'reason': reason,
      'textSnippet': (textSnippet ?? '').trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
