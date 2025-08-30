import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mahaseel/core/ui/toast.dart';

import 'package:mahaseel/features/auth/state/auth_controller.dart';
import '../models/chats.dart';
import 'chats_list_screen.dart'; // for chatRepoProvider

class ChatThreadScreen extends ConsumerStatefulWidget {
  final int conversationId;
  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  late WebSocketChannel _ch;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();

    // connect WS (provide wsBase + token from your auth)
    final repo = ref.read(chatRepoProvider);
    // TODO: replace with your real ws base + token
    _ch = repo.connectWS('wss://YOUR_API_BASE', widget.conversationId, 'JWT_TOKEN');

    _ch.stream.listen((data) {
      try {
        final dynamic decoded = (data is String) ? jsonDecode(data) : data;
        // Expected: {"type":"message","message":{...}}
        if (decoded is Map && decoded['type'] == 'message' && decoded['message'] is Map) {
          final msg = Message.fromJson(decoded['message'] as Map<String, dynamic>);
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      } catch (_) {
        // ignore parsing errors for now
      }
    });
  }

  Future<void> _load() async {
    final repo = ref.read(chatRepoProvider);
    _messages = await repo.listMessages(widget.conversationId);
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _ch.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('محادثة #${widget.conversationId}')),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i]; // ✅ define m
                  // Compare consistently: convert m.senderId to String or me.id to int
                  final mine = (me != null && m.senderId.toString() == me.id);

                  return Align(
                    // In RTL, my messages typically on the RIGHT
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: mine
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(m.body),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'اكتب رسالة...'),
                      onChanged: (_) {
                        // optionally send typing via WS
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = _ctrl.text.trim();
                      if (text.isEmpty) return;

                      try {
                        final repo = ref.read(chatRepoProvider);
                        final sent = await repo.sendMessage(widget.conversationId, text);
                        setState(() => _messages.add(sent));
                        _ctrl.clear();
                      } on DioException catch (e) {
                        final code = e.response?.statusCode;
                        final detail = (e.response?.data is Map)
                            ? e.response!.data['detail']
                            : null;

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(detail ?? 'تعذّر إرسال الرسالة (خطأ $code)'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        // use centralized toast helper
                        showToast(context, 'Unexpected error: $e');
                      }
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
