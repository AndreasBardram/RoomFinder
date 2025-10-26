import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../components/custom_styles.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';
import 'mere_information_lejlighed.dart';
import 'mere_information_ansøgning.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.room});
  final types.Room? room;

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) {
      return Scaffold(appBar: _appBar('Chat'), body: _loggedOut(context));
    }
    return room == null ? _RoomsPage(currentUser: auth) : _RoomPage(room: room!, currentUser: auth);
  }

  PreferredSizeWidget _appBar(String title) => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
      );

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

class _RoomsPage extends StatelessWidget {
  const _RoomsPage({required this.currentUser});
  final User currentUser;

  static const _hairline = Color(0xFFF1F5F9);
  static const _subtitle = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Chat'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _hairline),
        ),
      ),
      body: StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        builder: (_, snap) {
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return const Center(child: Text('Ingen samtaler endnu'));
          }
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 0, color: _hairline),
            itemBuilder: (_, i) {
              final room = rooms[i];
              final last = room.lastMessages?.isNotEmpty == true ? room.lastMessages!.last : null;
              String subtitle = '';
              if (last is types.TextMessage) subtitle = last.text;
              if (last is types.CustomMessage) {
                final m = last.metadata ?? {};
                final t = (m['title'] ?? '').toString();
                subtitle = t.isEmpty ? 'Vedhæftning' : t;
              }
              final time = last != null && last.createdAt != null
                  ? DateFormat.Hm('da').format(DateTime.fromMillisecondsSinceEpoch(last.createdAt!))
                  : '';
              return InkWell(
                onTap: () => Navigator.push(_, MaterialPageRoute(builder: (_) => ChatScreen(room: room))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _avatar(room, currentUser.uid),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_title(room, currentUser.uid),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: _subtitle),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (time.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(time, style: const TextStyle(fontSize: 11, color: _subtitle)),
                        ),
                    ],
                  ),
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
    if (other.imageUrl != null && other.imageUrl!.isNotEmpty) {
      return CircleAvatar(radius: 18, backgroundImage: NetworkImage(other.imageUrl!));
    }
    final name = (other.firstName?.isNotEmpty == true ? other.firstName! : room.name ?? 'B');
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'B';
    final color = _colorFromString(other.id);
    return CircleAvatar(radius: 18, backgroundColor: color, child: Text(letter, style: const TextStyle(color: Colors.white)));
  }

  String _title(types.Room room, String myId) {
    if (room.name != null && room.name!.isNotEmpty) return room.name!;
    final others = room.users.where((u) => u.id != myId);
    return others.map((u) => u.firstName ?? 'Bruger').join(', ');
  }

  static Color _colorFromString(String s) {
    final h = s.hashCode;
    final palette = [
      const Color(0xFF7C6CF4),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return palette[h.abs() % palette.length];
  }
}

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
    _sub = FirebaseChatCore.instance.messages(widget.room, limit: _limit).listen((m) => setState(() => _messages = m));
  }

  Future<void> _loadMore() async {
    setState(() => _limit += _page);
    await _sub.cancel();
    _listen();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _openAttachment(Map<String, dynamic> meta) async {
    final collection = meta['collection']?.toString();
    final id = meta['id']?.toString();
    if (collection == null || id == null) return;
    final snap = await FirebaseFirestore.instance.collection(collection).doc(id).get();
    if (!mounted || !snap.exists) return;
    final d = snap.data()!;
    if (collection == 'apartments') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MoreInformationScreen(data: d, parentCollection: collection, parentId: id)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MoreInformationApplicationScreen(data: d, parentCollection: collection, parentId: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const hairline = Color(0xFFF1F5F9);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(widget.room.name ?? 'Chat'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: hairline),
        ),
      ),
      body: Chat(
        messages: _messages,
        user: types.User(id: widget.currentUser.uid),
        showUserNames: true,
        showUserAvatars: true,
        theme: const DefaultChatTheme(
          backgroundColor: Colors.white,
          primaryColor: Colors.black,
          secondaryColor: Color(0xFFF6F7FA),
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
          receivedMessageBodyTextStyle: TextStyle(color: Colors.black87),
          inputBackgroundColor: Colors.white,
          inputTextColor: Colors.black,
          inputTextCursorColor: Colors.black,
          inputBorderRadius: BorderRadius.all(Radius.circular(16)),
          inputPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        customMessageBuilder: (types.CustomMessage m, {required int messageWidth}) {
          final meta = m.metadata ?? {};
          final img = (meta['imageUrl'] ?? '').toString();
          final title = (meta['title'] ?? '').toString();
          final subtitle = (meta['subtitle'] ?? '').toString();
          return InkWell(
            onTap: () => _openAttachment(Map<String, dynamic>.from(meta)),
            child: Container(
              width: messageWidth.toDouble(),
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img.isEmpty
                        ? Container(width: 64, height: 64, color: const Color(0xFFE5E7EB))
                        : Image.network(img, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.isEmpty ? 'Vedhæftning' : title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black45),
                ],
              ),
            ),
          );
        },
        onSendPressed: (types.PartialText msg) => FirebaseChatCore.instance.sendMessage(msg, widget.room.id),
        onEndReached: _loadMore,
        onEndReachedThreshold: 0.7,
      ),
    );
  }
}
