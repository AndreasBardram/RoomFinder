import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/block_service.dart';

class BlockedUsersScreen extends StatelessWidget {
  BlockedUsersScreen({super.key});

  final _blocks = BlockService();
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> _userDoc(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return d.data();
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Blokerede brugere', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _blocks.myBlocks(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Ingen blokerede brugere.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final blockedId = (data['blockedId'] ?? '') as String;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _userDoc(blockedId),
                builder: (context, userSnap) {
                  final u = userSnap.data ?? {};
                  final firstName = (u['firstName'] ?? '') as String;
                  final lastName = (u['lastName'] ?? '') as String;
                  final name = ('${firstName.trim()} ${lastName.trim()}').trim();
                  final subtitle = name.isEmpty ? blockedId : name;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFF6F7FA),
                            child: Icon(Icons.block, color: Colors.black),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Blokeret', style: TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(subtitle, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Color(0xFFE6E8EF), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              if (blockedId.isEmpty) return;
                              try {
                                await _blocks.unblockUser(blockedId);
                                if (context.mounted) _toast(context, 'Blokering fjernet.');
                              } catch (_) {
                                if (context.mounted) _toast(context, 'Kunne ikke fjerne blokering.');
                              }
                            },
                            child: const Text('Fjern'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
