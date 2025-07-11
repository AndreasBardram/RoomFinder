// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../components/custom_styles.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.room});

  /// null  → show the list of conversations (main tab)  
  /// non-null → open this specific chat room
  final types.Room? room;

  /* ------------------------------------------------------------------ helpers */

  // Title when user is not signed in
  Widget _loggedOut(BuildContext ctx) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: CustomButtonContainer(
                child: ElevatedButton(
                  style: customElevatedButtonStyle(),
                  onPressed: () =>
                      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Log ind'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: CustomButtonContainer(
                child: ElevatedButton(
                  style: customElevatedButtonStyle(),
                  onPressed: () => Navigator.push(
                      ctx, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                  child: const Text('Opret profil'),
                ),
              ),
            ),
          ],
        ),
      );

  // Derive a readable title from room/users
  String _roomTitle(types.Room r, String myId) {
    if (r.name != null && r.name!.isNotEmpty) return r.name!;
    final others = r.users.where((u) => u.id != myId).toList();
    return others.isEmpty
        ? 'Chat'
        : others.map((u) => u.firstName ?? 'Bruger').join(', ');
  }

  /* ------------------------------------------------------------------ build */

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // 0.  user not authenticated ------------------------------------------------
    if (currentUser == null) {
      return Scaffold(appBar: AppBar(title: const Text('Chat')), body: _loggedOut(context));
    }

    // 1.  conversations list ----------------------------------------------------
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: StreamBuilder<List<types.Room>>(
          stream: FirebaseChatCore.instance.rooms(),
          builder: (_, snapshot) {
            final rooms = snapshot.data ?? [];

            if (rooms.isEmpty) {
              return const Center(child: Text('Ingen samtaler endnu'));
            }

            return ListView.separated(
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) => ListTile(
                title: Text(_roomTitle(rooms[i], currentUser.uid)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(room: rooms[i])),
                ),
              ),
            );
          },
        ),
      );
    }

    // 2.  single chat room ------------------------------------------------------
    return StreamBuilder<List<types.Message>>(
      stream: FirebaseChatCore.instance.messages(room!),
      builder: (_, snapshot) {
        final messages = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(title: Text(room!.name ?? 'Chat')),
          body: Chat(
            messages: messages,
            user: types.User(id: currentUser.uid),
            onSendPressed: (types.PartialText msg) =>
                FirebaseChatCore.instance.sendMessage(msg, room!.id),
          ),
        );
      },
    );
  }
}
