import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/ad_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';
import 'chat_controller.dart';
import 'widgets/left_bubble.dart';
import 'widgets/right_bubble.dart';
import 'widgets/answer_bubble.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/auto_progress_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startChat());
  }

  Future<void> _startChat() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final profile = ref.read(userProfileProvider);
      final loader = ref.read(conversationLoaderProvider);
      final flow = await loader.loadOnboarding();

      if (!mounted) return;
      final isEn = ref.read(localeProvider) == 'en';
      await ref.read(chatProvider.notifier).startConversation(
            flow: flow,
            profile: profile,
            isEn: isEn,
          );
    } catch (e) {
      // Asset yüklenemezse onboarding'i tamamlanmış say, ana ekrana yönlendir
      if (!mounted) return;
      final profile = ref.read(userProfileProvider);
      await ref.read(userProfileProvider.notifier).completeOnboarding(profile);
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), // Unity: 0.2s
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final pendingAction = chatState.pendingAction;

    // Scroll to bottom when messages change
    ref.listen(chatProvider, (_, next) {
      if (next.messages.isNotEmpty) _scrollToBottom();

      // Handle navigation actions
      final action = next.pendingAction;
      if (action == 'open_coffee') {
        ref.read(chatProvider.notifier).clearPendingAction();
        context.go('/coffee');
      } else if (action == 'open_tarot') {
        ref.read(chatProvider.notifier).clearPendingAction();
        context.go('/tarot');
      } else if (action == 'open_astrology') {
        ref.read(chatProvider.notifier).clearPendingAction();
        context.go('/astrology');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(chatState),
          ),
          if (pendingAction == 'input_name' || pendingAction == 'input_age')
            _buildTextInput(pendingAction!),
          if (pendingAction == 'auto_complete')
            _buildAutoProgressBar(context),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.navBarBackground,
      title: ClipOval(
        child: Image.asset(
          'assets/images/magnusappicon_splash.png',
          height: 40,
          width: 40,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
      centerTitle: true,
      actions: const [],
    );
  }

  Widget _buildMessageList(ChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final msg = chatState.messages[index];
        return switch (msg) {
          MagnusMessage m => LeftBubble(
              text: m.text,
              colorTheme: m.colorTheme,
            ),
          UserMessage m => RightBubble(text: m.text),
          AnswerPrompt m => AnswerBubbleRow(
              answers: m.answers,
              layout: m.layout,
              onSelected: m.onSelected,
              showLegalButton: m.showLegalButton,
            ),
          TypingMessage _ => const TypingIndicator(),
        };
      },
    );
  }

  Widget _buildTextInput(String action) {
    final s = ref.read(l10nProvider);
    final hint = action == 'input_name' ? s.typeYourName : s.typeYourAge;
    final keyboardType = action == 'input_age'
        ? TextInputType.number
        : TextInputType.name;

    return Container(
      color: AppColors.navBarBackground,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                keyboardType: keyboardType,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                style: AppTextStyles.bubbleText,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.bubbleText.copyWith(
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _submitText,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _submitText(_textController.text),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.bubble1,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoProgressBar(BuildContext context) {
    return Container(
      color: AppColors.navBarBackground,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: AutoProgressButton(
          onComplete: () {
            ref.read(chatProvider.notifier).completeOnboarding();
          },
        ),
      ),
    );
  }

  Future<void> _adminBypass() async {
    final adminProfile = UserProfile(
      name: 'Anıl',
      lastName: 'Gedikoğlu',
      age: 42,
      gender: 'erkek',
      job: 'kamusektoru',
      maritalStatus: 'evli',
      birthDate: '1983-10-14',
      birthCity: 'Ankara',
      zodiacSign: 'Terazi',
      birthTime: '13:30',
      onboardingComplete: true,
    );
    await ref.read(userProfileProvider.notifier).save(adminProfile);
    // Dil seçimini de işaretle (yoksa router /language'a yönlendirebilir)
    await ref.read(languagePickedProvider.notifier).markPicked();
    // Admin modunda reklamlar kapalı
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_ads_disabled', true);
    AdService.instance.setAdsDisabled(true);
    if (mounted) context.go('/home');
  }

  void _submitText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _textController.clear();

    // Admin bypass
    final action = ref.read(chatProvider).pendingAction;
    if (action == 'input_name' && trimmed.toLowerCase() == 'godag') {
      _adminBypass();
      return;
    }

    // Save to profile if it's the name or age
    if (action == 'input_name') {
      ref.read(userProfileProvider.notifier).update(
            (p) => UserProfile(
              name: trimmed,
              age: p.age,
              gender: p.gender,
              job: p.job,
              maritalStatus: p.maritalStatus,
              birthDate: p.birthDate,
              birthCity: p.birthCity,
              zodiacSign: p.zodiacSign,
              onboardingComplete: p.onboardingComplete,
            ),
          );
    } else if (action == 'input_age') {
      final age = int.tryParse(trimmed) ?? 0;
      ref.read(userProfileProvider.notifier).update(
            (p) => UserProfile(
              name: p.name,
              age: age,
              gender: p.gender,
              job: p.job,
              maritalStatus: p.maritalStatus,
              birthDate: p.birthDate,
              birthCity: p.birthCity,
              zodiacSign: p.zodiacSign,
              onboardingComplete: p.onboardingComplete,
            ),
          );
    }

    ref.read(chatProvider.notifier).submitTextInput(trimmed);
  }
}
