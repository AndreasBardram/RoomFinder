// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';

import '../components/custom_styles.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.room});

  final types.Room? room; // null → list, set → single room

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) {
      return Scaffold(appBar: AppBar(title: const Text('Chat')), body: _loggedOut(context));
    }

    return room == null
        ? _RoomsPage(currentUser: auth)
        : _RoomPage(room: room!, currentUser: auth);
  }

  /* ---------- logged-out helper ---------- */

  Widget _loggedOut(BuildContext ctx) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _authBtn(ctx, 'Log ind', const LoginScreen()),
            const SizedBox(height: 16),
            _authBtn(ctx, 'Opret profil', const CreateAccountScreen()),
          ],
        ),
      );

  Widget _authBtn(BuildContext ctx, String label, Widget page) => SizedBox(
        width: 200,
        child: CustomButtonContainer(
          child: ElevatedButton(
            style: customElevatedButtonStyle(),
            onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)),
            child: Text(label),
          ),
        ),
      );
}

/* ──────────────────────────────────────────────────────────────────────────── */
/* 1. CONVERSATION LIST                                                        */
/* ──────────────────────────────────────────────────────────────────────────── */

class _RoomsPage extends StatelessWidget {
  const _RoomsPage({required this.currentUser});
  final User currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        builder: (_, snap) {
          final rooms = snap.data ?? [];

          if (rooms.isEmpty) {
            return const Center(child: Text('Ingen samtaler endnu'));
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final room = rooms[i];
              final last = room.lastMessages?.isNotEmpty == true ? room.lastMessages!.last : null;

              String subtitle = '';
              if (last is types.TextMessage) subtitle = last.text;
              final time = last != null && last.createdAt != null
                  ? DateFormat.Hm('da').format(
                      DateTime.fromMillisecondsSinceEpoch(last.createdAt!))
                  : '';

              return ListTile(
                leading: _avatar(room, currentUser.uid),
                title: Text(_title(room, currentUser.uid)),
                subtitle:
                    subtitle.isEmpty ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: time.isEmpty ? null : Text(time, style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _avatar(types.Room room, String myId) {
    final other = room.users.firstWhere((u) => u.id != myId, orElse: () => types.User(id: myId));
    final initial = (other.firstName?.isNotEmpty == true) ? other.firstName![0] : '🤖';
    return other.imageUrl != null
        ? CircleAvatar(backgroundImage: NetworkImage(other.imageUrl!))
        : CircleAvatar(child: Text(initial));
  }

  String _title(types.Room room, String myId) {
    if (room.name != null && room.name!.isNotEmpty) return room.name!;
    final others = room.users.where((u) => u.id != myId);
    return others.map((u) => u.firstName ?? 'Bruger').join(', ');
  }
}

/* ──────────────────────────────────────────────────────────────────────────── */
/* 2. SINGLE ROOM                                                              */
/* ──────────────────────────────────────────────────────────────────────────── */

class _RoomPage extends StatefulWidget {
  const _RoomPage({required this.room, required this.currentUser});
  final types.Room room;
  final User currentUser;

  @override
  State<_RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<_RoomPage> {
  static const int _page = 30;
  int _limit = _page;
  late StreamSubscription<List<types.Message>> _sub;
  List<types.Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _sub = FirebaseChatCore.instance
        .messages(widget.room, limit: _limit)
        .listen((m) => setState(() => _messages = m));
  }

  Future<void> _loadMore() async {
    setState(() => _limit += _page);
    _sub.cancel();
    _listen();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name ?? 'Chat')),
      body: Chat(
        messages: _messages,
        user: types.User(id: widget.currentUser.uid),
        showUserNames: true,
        showUserAvatars: true,
        theme: const DefaultChatTheme(
          primaryColor: Colors.black,
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
          inputBackgroundColor: Colors.white,
          inputTextColor: Colors.black,
        ),
        onSendPressed: (types.PartialText msg) =>
            FirebaseChatCore.instance.sendMessage(msg, widget.room.id),
        onEndReached: _loadMore,
        onEndReachedThreshold: 0.7,
      ),
    );
  }
}
