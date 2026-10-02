import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/family_message_model.dart';
import '../../models/family_model.dart';
import '../../models/user_role.dart';
import '../../services/family_session.dart';
import '../../services/firestore_service.dart';
import '../../services/message_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/firestore_codec.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_views.dart';

class FamilyMessagesScreen extends StatelessWidget {
  const FamilyMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      constrainWidth: false,
      builder: (BuildContext context, FamilyScope scope) {
        final bool isParent = scope.user.role == UserRole.parent;
        return StreamBuilder<FamilyModel?>(
          stream: FirestoreService.instance.watchFamily(scope.familyId),
          builder: (BuildContext context, AsyncSnapshot<FamilyModel?> family) {
            final String parentId = family.data?.parentId ?? '';
            final String? childId = isParent
                ? scope.selectedChild?.uid
                : scope.user.uid;
            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: AppTopBar(
                      title: isParent ? 'Messages' : 'Family Messages',
                      subtitle: isParent
                          ? scope.selectedChild?.name
                          : 'Chat with your parent',
                    ),
                  ),
                  if (isParent)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                      ),
                      child: ChildPicker(
                        children: scope.children,
                        selectedId: scope.selectedChild?.uid,
                        onSelected: FamilySession.instance.selectChild,
                      ),
                    ),
                  Expanded(
                    child: childId == null || parentId.isEmpty
                        ? MessageView(
                            isParent
                                ? 'Add a child to start messaging.'
                                : 'Unable to find your parent chat.',
                            icon: Icons.chat_bubble_outline_rounded,
                          )
                        : _ConversationPane(
                            key: ValueKey<String>('$parentId-$childId'),
                            familyId: scope.familyId,
                            parentId: parentId,
                            childId: childId,
                            myId: scope.user.uid,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ConversationPane extends StatefulWidget {
  const _ConversationPane({
    super.key,
    required this.familyId,
    required this.parentId,
    required this.childId,
    required this.myId,
  });

  final String familyId;
  final String parentId;
  final String childId;
  final String myId;

  @override
  State<_ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends State<_ConversationPane> {
  final TextEditingController _input = TextEditingController();
  final List<FamilyMessageModel> _items = <FamilyMessageModel>[];
  StreamSubscription<List<FamilyMessageModel>>? _subscription;
  bool _hydrated = false;
  bool _sending = false;
  String? _error;
  String? _markedKey;

  @override
  void initState() {
    super.initState();
    _subscription = MessageService.instance
        .watchConversation(
          familyId: widget.familyId,
          parentId: widget.parentId,
          childId: widget.childId,
        )
        .listen(_onLive, onError: _onError);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _input.dispose();
    super.dispose();
  }

  String get _peerId =>
      widget.myId == widget.parentId ? widget.childId : widget.parentId;

  void _onError(Object error) {
    if (!mounted) return;
    setState(() => _error = error.toString());
  }

  void _onLive(List<FamilyMessageModel> live) {
    if (!mounted) return;
    setState(() {
      _error = null;
      if (!_hydrated) {
        _hydrate(live);
        _hydrated = true;
      } else {
        _merge(live);
      }
    });
    _queueMarkRead(live);
  }

  void _hydrate(List<FamilyMessageModel> live) {
    final List<FamilyMessageModel> localOnly = _items
        .where(
          (FamilyMessageModel item) => live.every(
            (FamilyMessageModel incoming) => incoming.messageId != item.messageId,
          ),
        )
        .toList();
    _items
      ..clear()
      ..addAll(live.reversed);
    for (final FamilyMessageModel local in localOnly.reversed) {
      _items.insert(0, local);
    }
  }

  void _merge(List<FamilyMessageModel> live) {
    for (final FamilyMessageModel incoming in live) {
      final int index = _items.indexWhere(
        (FamilyMessageModel item) => item.messageId == incoming.messageId,
      );
      if (index >= 0) {
        final FamilyMessageModel current = _items[index];
        _items[index] = incoming.copyWith(
          createdAt: incoming.hasValidTimestamp
              ? incoming.createdAt
              : current.createdAt,
        );
        continue;
      }
      _items.insert(0, incoming);
    }
  }

  void _queueMarkRead(List<FamilyMessageModel> live) {
    final String key =
        '${live.length}-${live.where((FamilyMessageModel item) => !item.read).length}';
    if (_markedKey == key) return;
    _markedKey = key;
    unawaited(
      MessageService.instance.markConversationRead(
        familyId: widget.familyId,
        readerId: widget.myId,
        messages: live,
      ),
    );
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    final String messageId = MessageService.instance.newMessageId(
      widget.familyId,
    );
    final FamilyMessageModel outgoing = FamilyMessageModel(
      messageId: messageId,
      senderId: widget.myId,
      receiverId: _peerId,
      text: text,
      read: false,
      createdAt: DateTime.now(),
    );
    setState(() {
      _sending = true;
      _items.insert(0, outgoing);
    });
    try {
      await MessageService.instance.sendMessage(
        familyId: widget.familyId,
        messageId: messageId,
        senderId: widget.myId,
        receiverId: _peerId,
        text: text,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _items.removeWhere(
            (FamilyMessageModel item) => item.messageId == messageId,
          );
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _buildThread() {
    if (_error != null && _items.isEmpty) {
      return const MessageView('Unable to load messages.');
    }
    if (!_hydrated && _items.isEmpty) {
      return const LoadingView();
    }
    if (_items.isEmpty) {
      return const MessageView(
        'No messages yet.',
        icon: Icons.chat_bubble_outline_rounded,
      );
    }
    return ListView.builder(
      key: const PageStorageKey<String>('family-chat-thread'),
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.md,
      ),
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        final FamilyMessageModel message = _items[index];
        return _Bubble(
          key: ValueKey<String>(message.messageId),
          message: message,
          mine: message.isMine(widget.myId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: <Widget>[
          Expanded(child: _buildThread()),
          Material(
            color: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x14082A4D),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.sm,
                  AppSpacing.pageHorizontal,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Write a message',
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: IconButton.filled(
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.mine,
  });

  final FamilyMessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = mine ? AppColors.primary : Colors.white;
    final Color foreground = mine ? Colors.white : AppColors.ink;
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: radius,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x14082A4D),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (message.createdAt != null)
                    formatRelative(message.createdAt!),
                  if (mine) (message.read ? 'Read' : 'Sent'),
                ].join(' · '),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
