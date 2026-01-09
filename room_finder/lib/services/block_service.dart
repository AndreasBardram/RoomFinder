import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  String _docId(String blockerId, String blockedId) => '${blockerId}_$blockedId';

  Future<void> blockUser(String blockedId) async {
    final id = _docId(_uid, blockedId);
    await _db.collection('blocks').doc(id).set({
      'blockerId': _uid,
      'blockedId': blockedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String blockedId) async {
    final id = _docId(_uid, blockedId);
    await _db.collection('blocks').doc(id).delete();
  }

  Future<bool> isBlockedEitherWayOnce(String otherId) async {
    final a = await _db.collection('blocks').doc(_docId(_uid, otherId)).get();
    if (a.exists) return true;
    final b = await _db.collection('blocks').doc(_docId(otherId, _uid)).get();
    return b.exists;
  }

  Stream<bool> blockStateWith(String otherId) {
    final controller = StreamController<bool>.broadcast();
    StreamSubscription? subA;
    StreamSubscription? subB;

    var a = false;
    var b = false;

    void emit() {
      if (!controller.isClosed) controller.add(a || b);
    }

    subA = _db.collection('blocks').doc(_docId(_uid, otherId)).snapshots().listen((s) {
      a = s.exists;
      emit();
    });

    subB = _db.collection('blocks').doc(_docId(otherId, _uid)).snapshots().listen((s) {
      b = s.exists;
      emit();
    });

    controller.onCancel = () async {
      await subA?.cancel();
      await subB?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myBlocks() {
    return _db
        .collection('blocks')
        .where('blockerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
