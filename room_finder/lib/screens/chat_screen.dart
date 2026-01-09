import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../components/custom_styles.dart';
import '../components/no_transition.dart';
import '../services/ugc_service.dart';
import 'log_in_screen.dart';
import 'create_profile_screen.dart';
import 'more_information_apartment.dart';
import 'more_information_application.dart';
import 'settings_screen.dart';

const kBrandPurple = Color(0xFF7C6CF4);

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.room});
  final types.Room? room;

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) {
      return Scaffold(appBar: _appBar(context, 'Chat'), body: _loggedOut(context));
    }
    return room == null ? _RoomsPage(currentUser: auth) : _RoomPage(room: room!, currentUser: auth);
  }

  PreferredSizeWidget _appBar(BuildContext context, String title) => AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => pushNoAnim(context, const SettingsScreen()),
          ),
        ],
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
            onPressed: () => pushNoAnim(ctx, page),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => pushNoAnim(context, const SettingsScreen()),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _hairline),
        ),
      ),
      body: StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        builder: (ctx, snap) {
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return const Center(child: Text('Ingen samtaler endnu'));
          }
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 0, color: _hairline),
            itemBuilder: (itemCtx, i) {
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
                onTap: () => pushNoAnim(itemCtx, ChatScreen(room: room)),
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
                            Text(
                              _title(room, currentUser.uid),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
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
    return CircleAvatar(
      radius: 18,
      backgroundColor: kBrandPurple,
      child: Text(letter, style: const TextStyle(color: Colors.white)),
    );
  }

  String _title(types.Room room, String myId) {
    if (room.name != null && room.name!.isNotEmpty) return room.name!;
    final others = room.users.where((u) => u.id != myId);
    return others.map((u) => u.firstName ?? 'Bruger').join(', ');
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
  static const int _pageSize = 30;

  int _limit = _pageSize;
  late StreamSubscription<List<types.Message>> _messagesSub;
  StreamSubscription<RoomModerationState>? _moderationSub;

  final _ugc = UgcService();

  List<types.Message> _messages = [];

  bool _isBlocked = false;
  String? _blockedBy;
  String? _blockedUserId;

  String get _myId => widget.currentUser.uid;

  String? get _otherUserId {
    final other = widget.room.users.where((u) => u.id != _myId).toList();
    if (other.isEmpty) return null;
    return other.first.id;
  }

  @override
  void initState() {
    super.initState();
    _listenMessages();
    _listenModeration();
  }

  void _listenMessages() {
    _messagesSub = FirebaseChatCore.instance.messages(widget.room, limit: _limit).listen(
          (m) => setState(() => _messages = m),
        );
  }

  void _listenModeration() {
    _moderationSub = _ugc.roomModerationState(widget.room.id).listen((s) {
      if (!mounted) return;
      setState(() {
        _isBlocked = s.isBlocked;
        _blockedBy = s.blockedBy;
        _blockedUserId = s.blockedUserId;
      });
    });
  }

  Future<void> _loadMore() async {
    setState(() => _limit += _pageSize);
    await _messagesSub.cancel();
    _listenMessages();
  }

  @override
  void dispose() {
    _messagesSub.cancel();
    _moderationSub?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openAttachment(Map<String, dynamic> meta) async {
    final collection = meta['collection']?.toString();
    final id = meta['id']?.toString();
    if (collection == null || id == null) return;

    final snap = await FirebaseFirestore.instance.collection(collection).doc(id).get();
    if (!mounted || !snap.exists) return;

    final d = snap.data()!;
    if (collection == 'apartments') {
      await pushNoAnim(context, MoreInformationScreen(data: d, parentCollection: collection, parentId: id));
    } else {
      await pushNoAnim(context, MoreInformationApplicationScreen(data: d, parentCollection: collection, parentId: id));
    }
  }

  void _send(dynamic partialMessage) {
    if (_isBlocked) {
      _toast('Samtalen er blokeret.');
      return;
    }

    try {
      if (partialMessage is types.PartialText) {
        final t = partialMessage.text.trim();
        if (t.isEmpty) return;
        FirebaseChatCore.instance.sendMessage(types.PartialText(text: t), widget.room.id);
        return;
      }

      FirebaseChatCore.instance.sendMessage(partialMessage, widget.room.id);
    } catch (_) {
      _toast('Kunne ikke sende besked.');
    }
  }

  Future<String?> _pickReportReason({required String title}) async {
    final controller = TextEditingController();
    final reasons = ['Spam', 'Chikane', 'Upassende indhold', 'Svindel', 'Andet'];
    String selected = reasons.first;

    final res = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              final isOther = selected == 'Andet';
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  for (final r in reasons)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: r,
                      groupValue: selected,
                      onChanged: (v) => setSheetState(() => selected = v ?? reasons.first),
                      title: Text(r),
                      activeColor: Colors.black,
                    ),
                  if (isOther) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        hintText: 'Skriv kort hvad der er galt',
                        filled: true,
                        fillColor: const Color(0xFFF6F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      final reason = selected == 'Andet' ? controller.text.trim() : selected;
                      if (reason.isEmpty) {
                        Navigator.pop(ctx);
                        return;
                      }
                      Navigator.pop(ctx, reason);
                    },
                    child: const Text('Send rapport'),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );

    controller.dispose();
    return res;
  }

  Future<void> _reportUser() async {
    final otherId = _otherUserId;
    if (otherId == null) return;

    final reason = await _pickReportReason(title: 'Rapportér bruger');
    if (reason == null || reason.trim().isEmpty) return;

    try {
      await _ugc.reportUser(roomId: widget.room.id, reportedUserId: otherId, reason: reason);
      _toast('Tak. Rapporten er sendt.');
    } catch (_) {
      _toast('Kunne ikke sende rapport.');
    }
  }

  Future<void> _reportMessage(types.Message message) async {
    final reason = await _pickReportReason(title: 'Rapportér besked');
    if (reason == null || reason.trim().isEmpty) return;

    final authorId = message.author.id;
    final snippet = message is types.TextMessage ? message.text : '';

    try {
      await _ugc.reportMessage(
        roomId: widget.room.id,
        messageId: message.id,
        messageAuthorId: authorId,
        reason: reason,
        textSnippet: snippet,
      );
      _toast('Tak. Rapporten er sendt.');
    } catch (_) {
      _toast('Kunne ikke sende rapport.');
    }
  }

  Future<void> _toggleBlock() async {
    final otherId = _otherUserId;
    if (otherId == null) return;

    if (_isBlocked) {
      try {
        await _ugc.unblockRoom(roomId: widget.room.id);
        _toast('Blokering fjernet.');
      } catch (_) {
        _toast('Kunne ikke fjerne blokering.');
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Blokér bruger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                'Når du blokerer, kan der ikke sendes nye beskeder i samtalen.',
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.35),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0xFFE6E8EF), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuller'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Blokér'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;

    try {
      await _ugc.blockRoom(roomId: widget.room.id, blockedUserId: otherId);
      _toast('Bruger blokeret.');
    } catch (_) {
      _toast('Kunne ikke blokere bruger.');
    }
  }

  void _openRoomMenu() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_isBlocked ? FluentIcons.lock_open_24_regular : FluentIcons.lock_closed_24_regular),
              title: Text(_isBlocked ? 'Fjern blokering' : 'Blokér bruger'),
              onTap: () async {
                Navigator.pop(ctx);
                await _toggleBlock();
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.flag_24_regular),
              title: const Text('Rapportér bruger'),
              onTap: () async {
                Navigator.pop(ctx);
                await _reportUser();
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.settings_24_regular),
              title: const Text('Indstillinger'),
              onTap: () {
                Navigator.pop(ctx);
                pushNoAnim(context, const SettingsScreen());
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _blockedBanner() {
    if (!_isBlocked) return const SizedBox.shrink();

    final isMe = _blockedBy == _myId;
    final txt = isMe ? 'Du har blokeret denne samtale.' : 'Denne samtale er blokeret.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(FluentIcons.warning_24_regular, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(txt, style: const TextStyle(fontSize: 13))),
          TextButton(
            onPressed: _toggleBlock,
            child: Text(isMe ? 'Fjern' : 'Fjern blokering'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hairline = Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(widget.room.name ?? 'Chat'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.more_horizontal_24_regular),
            onPressed: _openRoomMenu,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: hairline),
        ),
      ),
      body: Column(
        children: [
          _blockedBanner(),
          Expanded(
            child: Chat(
              messages: _messages,
              user: types.User(id: _myId),
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
                userNameTextStyle: TextStyle(
                  color: kBrandPurple,
                  fontWeight: FontWeight.w600,
                ),
                userAvatarNameColors: <Color>[kBrandPurple],
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
                              Text(
                                title.isEmpty ? 'Vedhæftning' : title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              if (subtitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
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
              onSendPressed: (types.PartialText msg) => _send(msg),
              onEndReached: _loadMore,
              onEndReachedThreshold: 0.7,
              onMessageLongPress: (ctx, message) async {
                if (message.author.id == _myId) return;
                await _reportMessage(message);
              },
            ),
          ),
        ],
      ),
    );
  }
}
