import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/services/knowledge_base_service.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_bloc.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_event.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_state.dart';
import 'package:aquatrack_pro/injection_container.dart' as di;
import 'package:aquatrack_pro/core/widgets/gradient_scaffold.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';

import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/dashboard/domain/entities/dashboard_data.dart';

class AiAssistantPage extends StatefulWidget {
  final String userId;
  final AthleteEntity athlete;
  final DashboardData? dashboardData;
  final Map<String, dynamic> extraContext;

  const AiAssistantPage({
    super.key,
    required this.userId,
    required this.athlete,
    this.dashboardData,
    this.extraContext = const {},
  });

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AiBloc>();
    bloc.initialize(widget.userId, widget.athlete);
    if (widget.dashboardData != null) {
      final dd = widget.dashboardData!;
      bloc.setContextData(
        recentLogs: dd.recentLogs,
        todayLog: dd.todayLog,
        acwr: dd.acwr,
        stressScore: dd.stressScore,
      );
    }
    bloc.add(const LoadHistoryEvent());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || context.read<AiBloc>().state is AiLoading) return;
    _inputController.clear();
    final ctx = <String, dynamic>{
      'age': '${widget.athlete.age}',
      'gender': widget.athlete.gender == Gender.male ? 'ذكر' : 'أنثى',
      ...widget.extraContext,
    };
    if (widget.dashboardData?.todayLog != null) {
      final log = widget.dashboardData!.todayLog!;
      if (log.restingHR != null) ctx['hr'] = '${log.restingHR}';
      if (log.sleepHours != null) ctx['sleep'] = '${log.sleepHours}';
    }
    context.read<AiBloc>().add(SendMessageStreamEvent(
      question: text.trim(),
      athleteName: widget.athlete.name,
      context: ctx,
    ));
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _onSuggestionTap(String suggestion) {
    _inputController.text = suggestion;
    _sendMessage(suggestion);
  }

  void _showBookManager() {
    final kb = di.sl<KnowledgeBaseService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BookManagerSheet(kb: kb),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final isRtl = t.textDirection == TextDirection.rtl;

    return Directionality(
      textDirection: t.textDirection,
      child: GradientScaffold(
        appBar: AppBar(
          title: Text(t.translate('ai_assistant')),
          actions: [
            BlocBuilder<AiBloc, AiState>(
              builder: (context, blocState) {
                if (blocState is AiLoaded) {
                  final remaining = blocState.maxMessages - blocState.messagesUsedToday;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Chip(
                      avatar: Icon(
                        Icons.message_outlined,
                        size: 16,
                        color: remaining > 5 ? AppColors.success : AppColors.warning,
                      ),
                      label: Text(
                        t.translate('messages_remaining', params: {'count': '$remaining'}),
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu_book_outlined),
              tooltip: 'إدارة الكتب المرجعية',
              onPressed: _showBookManager,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<AiBloc, AiState>(
                builder: (context, blocState) {
                  if (blocState is AiInitial) {
                    return _buildWelcome(t);
                  }
                  if (blocState is AiStreaming) {
                    return _buildChatList(
                      blocState.currentMessages,
                      t,
                      streamingText: blocState.partialAnswer,
                    );
                  }
                  if (blocState is AiLoading) {
                    if (blocState.currentMessages.isEmpty) {
                      return _buildWelcome(t);
                    }
                    return _buildChatList(blocState.currentMessages, t);
                  }
                  if (blocState is AiLoaded) {
                    if (blocState.messages.isEmpty) {
                      return _buildWelcome(t);
                    }
                    return _buildChatList(blocState.messages, t);
                  }
                  if (blocState is AiError) {
                    if (blocState.currentMessages.isEmpty) {
                      return _buildError(blocState.message, t);
                    }
                    return _buildChatList(blocState.currentMessages, t, errorMessage: blocState.message);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            BlocBuilder<AiBloc, AiState>(
              builder: (context, blocState) {
                if (blocState is AiLoading && blocState.currentMessages.isNotEmpty) {
                  return _buildTypingIndicator(t);
                }
                return const SizedBox.shrink();
              },
            ),
            _buildDisclaimer(t),
            _buildInputBar(t, isRtl),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(AppLocalizations t) {
    final suggestions = [
      t.translate('ai_suggestion_1', params: {'name': widget.athlete.name}),
      t.translate('ai_suggestion_2', params: {'name': widget.athlete.name}),
      t.translate('ai_suggestion_3', params: {'name': widget.athlete.name}),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        // AI welcome bubble
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: GlassContainer(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 16,
                  color: AppColors.primary.withAlpha(20),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                  child: Text(
                    t.translate('ai_welcome', params: {'name': widget.athlete.name}),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t.translate('ai_context', params: {
            'name': widget.athlete.name,
            'sleep': '${widget.extraContext['sleep'] ?? '--'}',
            'hr': '${widget.extraContext['hr'] ?? '--'}',
            'acwr': '${widget.extraContext['acwr'] ?? '--'}',
          }),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        Text(
          t.translate('ai_suggestions'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 13)),
            onPressed: () => _onSuggestionTap(s.replaceAll('@name', widget.athlete.name)),
            avatar: const Icon(Icons.lightbulb_outline, size: 16),
          ),
        )),
      ],
    );
  }

  Widget _buildChatList(List<AiMessageEntity> messages, AppLocalizations t, {String? errorMessage, String? streamingText}) {
    final bubbles = <Widget>[];
    for (final msg in messages) {
      if (msg.trigger == AiTrigger.userQuery && msg.question.isNotEmpty) {
        bubbles.add(_buildUserBubble(msg, t));
      }
      if (msg.answer.isNotEmpty) {
        bubbles.add(_buildAiBubble(msg, t));
      }
    }
    if (streamingText != null && streamingText.isNotEmpty) {
      bubbles.add(_buildStreamingBubble(streamingText, t));
    }
    if (errorMessage != null) {
      bubbles.add(_buildErrorInline(errorMessage, t));
    }
    if (bubbles.isEmpty) return _buildWelcome(t);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: bubbles.length,
      itemBuilder: (context, index) => bubbles[index],
    );
  }

  Widget _buildUserBubble(AiMessageEntity msg, AppLocalizations t) {
    final isRtl = t.textDirection == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isRtl ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF1200E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isRtl ? 4 : 16),
                  bottomRight: Radius.circular(isRtl ? 16 : 4),
                ),
              ),
              child: Text(
                msg.question,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(AiMessageEntity msg, AppLocalizations t) {
    final isRtl = t.textDirection == TextDirection.rtl;
    final suggestions = _extractSuggestions(msg.answer);
    final answerText = _stripSuggestions(msg.answer);
    final hasRated = msg.feedback != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: GlassContainer(
              width: MediaQuery.of(context).size.width * 0.72,
              padding: const EdgeInsets.all(14),
              color: Theme.of(context).cardTheme.color?.withAlpha(80) ?? AppColors.darkSurface.withAlpha(80),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    answerText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (msg.citations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Text(
                      t.translate('citation'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    ...msg.citations.map((cit) => _buildCitation(cit)),
                  ],
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: suggestions.map((s) => _buildSuggestionChip(s, t)).toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasRated)
                        Icon(
                          msg.feedback == UserFeedback.helpful
                              ? Icons.thumb_up
                              : Icons.thumb_down,
                          size: 14,
                          color: msg.feedback == UserFeedback.helpful
                              ? AppColors.success
                              : AppColors.danger,
                        )
                      else ...[
                        InkWell(
                          onTap: () => context.read<AiBloc>().add(
                            RateMessageEvent(
                              messageId: msg.id,
                              feedback: UserFeedback.helpful,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.thumb_up_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => context.read<AiBloc>().add(
                            RateMessageEvent(
                              messageId: msg.id,
                              feedback: UserFeedback.notHelpful,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.thumb_down_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _urlRegExp = RegExp(r'https?://[^\s]+');
  static final _bulletRegExp = RegExp(r'^[•\-*]\s*');

  Widget _buildCitation(String cit) {
    final urlMatch = _urlRegExp.firstMatch(cit);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: urlMatch != null
          ? Semantics(
              button: true,
              label: 'نسخ الرابط',
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: urlMatch.group(0)!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ الرابط'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Text(
                  cit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.info,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            )
          : Text(
              cit,
              style: const TextStyle(fontSize: 11, color: AppColors.info),
            ),
    );
  }

  Widget _buildSuggestionChip(String suggestion, AppLocalizations t) {
    return ActionChip(
      label: Text(suggestion, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () => _sendMessage(suggestion),
    );
  }

  List<String> _extractSuggestions(String answer) {
    try {
      final results = <String>[];
      final lines = answer.split('\n');
      bool inFollowUp = false;
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.contains('المتابعة') || trimmed.startsWith('## المتابعة')) {
          inFollowUp = true;
          continue;
        }
        if (inFollowUp) {
          if (trimmed.startsWith('##') || trimmed.startsWith('===') || trimmed.startsWith('[')) {
            break;
          }
          final cleaned = trimmed.replaceAll(_bulletRegExp, '');
          if (cleaned.endsWith('؟') || cleaned.endsWith('?') || cleaned.endsWith('~')) {
            results.add(cleaned);
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  String _stripSuggestions(String answer) {
    try {
      final lines = answer.split('\n');
      final result = <String>[];
      for (final line in lines) {
        if (line.contains('المتابعة') || line.startsWith('## المتابعة')) break;
        result.add(line);
      }
      return result.join('\n').trim();
    } catch (_) {
      return answer;
    }
  }

  Widget _buildStreamingBubble(String text, AppLocalizations t) {
    final isRtl = t.textDirection == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: GlassContainer(
              width: MediaQuery.of(context).size.width * 0.72,
              padding: const EdgeInsets.all(14),
              color: AppColors.primary.withAlpha(20),
              borderRadius: 16,
              border: Border.all(color: AppColors.primary.withAlpha(50)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 16,
            color: Theme.of(context).cardTheme.color?.withAlpha(80) ?? AppColors.darkSurface.withAlpha(80),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent.withValues(alpha:  0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted.withValues(alpha:  0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        t.translate('medical_disclaimer'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textMuted.withValues(alpha:  0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildInputBar(AppLocalizations t, bool isRtl) {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      borderRadius: 24,
      color: Theme.of(context).cardTheme.color?.withAlpha(80) ?? AppColors.darkSurface.withAlpha(80),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textDirection: t.textDirection,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: t.translate('type_question'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<AiBloc, AiState>(
              builder: (context, state) {
                final canSend = state is AiLoaded ? state.canSendMore : true;
                final isLoading = state is AiLoading || state is AiStreaming;
                return IconButton.filled(
                  onPressed: (canSend && !isLoading)
                      ? () => _sendMessage(_inputController.text)
                      : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: AppColors.border,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorInline(String message, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              t.translate('error'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<AiBloc>().add(const LoadHistoryEvent()),
              icon: const Icon(Icons.refresh),
              label: Text(t.translate('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookManagerSheet extends StatefulWidget {
  final KnowledgeBaseService kb;
  const _BookManagerSheet({required this.kb});

  @override
  State<_BookManagerSheet> createState() => _BookManagerSheetState();
}

class _BookManagerSheetState extends State<_BookManagerSheet> {
  late List<String> _books;

  @override
  void initState() {
    super.initState();
    _books = widget.kb.getBookTitles();
  }

  void _refresh() => setState(() => _books = widget.kb.getBookTitles());

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    final name = file.name.replaceAll(RegExp(r'\.(txt|pdf)$'), '');
    final bytes = file.bytes;
    if (bytes == null && file.path == null) return;

    String content;
    try {
      if (name.endsWith('pdf') || file.name.endsWith('.pdf')) {
        if (bytes != null) {
          content = widget.kb.extractTextFromBytes(bytes);
        } else {
          content = await widget.kb.extractTextFromPdf(file.path!);
        }
      } else {
        if (bytes != null) {
          content = String.fromCharCodes(bytes);
        } else {
          content = await widget.kb.readTextFile(file.path!);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل قراءة الملف: $e')),
      );
      return;
    }

    if (content.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الملف فارغ أو غير قابل للقراءة')),
      );
      return;
    }

    await widget.kb.addBook(title: name, content: content);
    _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تمت إضافة "$name" (${content.length} حرف)')),
    );
  }

  void _addBook() {
    final ctrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة كتاب مرجعي'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'اسم الكتاب',
                  hintText: 'مثال: التغذية للسباحين',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'نص الكتاب',
                  hintText: 'الصق نص الكتاب هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
              await widget.kb.addBook(title: ctrl.text.trim(), content: contentCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, size: 24),
              const SizedBox(width: 8),
              const Text('الكتب المرجعية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_books.length} كتاب', style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.upload_file, color: AppColors.info),
                tooltip: 'رفع ملف txt أو pdf',
                onPressed: _pickFile,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                tooltip: 'إضافة يدوية',
                onPressed: _addBook,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ارفع ملفات .txt أو .pdf أو أضف النص يدوياً — المساعد يرجع للكتب عند الإجابة',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.7)),
          ),
          if (_books.isEmpty) ...[
            const SizedBox(height: 24),
            const Center(child: Text('لا توجد كتب مضافة بعد. أضف كتب التغذية والتدريب الرياضي!')),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (ctx, i) {
                  final bookTitle = _books[i];
                  final struct = widget.kb.getBookStructure(bookTitle);
                  final chapters = struct[bookTitle] ?? [];
                  return ExpansionTile(
                    leading: const Icon(Icons.book, color: AppColors.accent),
                    title: Text(bookTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${chapters.length} فصل/قسم', style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () async {
                        await widget.kb.removeBook(bookTitle);
                        _refresh();
                      },
                    ),
                    children: chapters.take(15).map((ch) => Padding(
                      padding: const EdgeInsets.only(right: 40, top: 2, bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_left, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(ch, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
