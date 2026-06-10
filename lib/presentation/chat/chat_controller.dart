import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/zodiac_calculator.dart';
import '../../data/models/chat_node.dart';
import '../../data/models/user_profile.dart';
import '../../data/providers.dart';
import '../../engine/conversation_engine.dart';

// ─── Chat message types shown in the ListView ─────────────────────────────────

sealed class ChatMessage {}

class MagnusMessage extends ChatMessage {
  final String text;
  final BubbleColorTheme colorTheme;
  MagnusMessage(this.text, {this.colorTheme = BubbleColorTheme.color1});
}

class UserMessage extends ChatMessage {
  final String text;
  UserMessage(this.text);
}

class AnswerPrompt extends ChatMessage {
  final List<String> answers;
  final AnswerLayout layout;
  final void Function(int) onSelected;
  final bool showLegalButton;
  AnswerPrompt({
    required this.answers,
    required this.layout,
    required this.onSelected,
    this.showLegalButton = false,
  });
}

class TypingMessage extends ChatMessage {}

// ─── State ────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isComplete;
  final String? pendingAction;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isComplete = false,
    this.pendingAction,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isComplete,
    String? pendingAction,
    bool clearAction = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isComplete: isComplete ?? this.isComplete,
      pendingAction: clearAction ? null : (pendingAction ?? this.pendingAction),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatState> {
  ConversationEngine? _engine;
  bool _firstAnswerShown = false;

  @override
  ChatState build() => const ChatState();

  // Expose engine variables so the screen can persist them to UserProfile
  Map<String, String> get engineVariables =>
      _engine?.variables ?? const {};

  Future<void> startConversation({
    required ConversationFlow flow,
    required UserProfile profile,
    bool isEn = false,
  }) async {
    _engine = ConversationEngine(flow: flow, profile: profile, isEn: isEn);
    state = const ChatState();
    final resolved = _engine!.start();
    await _showMagnusMessage(resolved);
  }

  Future<void> _showMagnusMessage(ResolvedNode resolved) async {
    state = state.copyWith(
      messages: [...state.messages, TypingMessage()],
      isTyping: true,
    );

    final delay = _typingDelayFor(resolved.resolvedMessage.length);
    await Future.delayed(delay);

    if (!state.isTyping) return;

    final messages = state.messages.where((m) => m is! TypingMessage).toList();
    messages.add(MagnusMessage(
      resolved.resolvedMessage,
      colorTheme: resolved.node.bubbleColor,
    ));

    final action = _getNodeAction(resolved);

    if (resolved.hasAnswers && action == null) {
      final isFirst = !_firstAnswerShown;
      _firstAnswerShown = true;
      messages.add(AnswerPrompt(
        answers: resolved.resolvedAnswers,
        layout: resolved.node.answerLayout,
        onSelected: (index) => _onAnswerSelected(index, resolved),
        showLegalButton: isFirst,
      ));
    }

    state = state.copyWith(
      messages: messages,
      isTyping: false,
      pendingAction: action,
    );
  }

  void _onAnswerSelected(int index, ResolvedNode currentResolved) {
    final messages = state.messages.where((m) => m is! AnswerPrompt).toList();
    final userText = currentResolved.resolvedAnswers[index];
    messages.add(UserMessage(userText));
    state = state.copyWith(messages: messages);

    final answer = currentResolved.node.answers[index];

    // Navigation actions — persist profile first, then expose action
    if (answer.action != null && !answer.action!.startsWith('input_')) {
      // Advance engine so setVariables on this answer are applied
      _engine!.selectAnswer(index);
      _persistProfileFromEngine();
      state = state.copyWith(messages: messages, pendingAction: answer.action);
      return;
    }

    // Input actions (text fields)
    if (answer.action != null && answer.action!.startsWith('input_')) {
      state = state.copyWith(messages: messages, pendingAction: answer.action);
      return;
    }

    final next = _engine!.selectAnswer(index);
    if (next == null) {
      _persistProfileFromEngine();
      state = state.copyWith(messages: messages, isComplete: true);
      return;
    }

    _showMagnusMessage(next);
  }

  /// Called by UI when a text input completes (name, age).
  void submitTextInput(String value) {
    _engine?.setVariable(_currentInputVariable(), value);

    final messages = state.messages.where((m) => m is! AnswerPrompt).toList();
    messages.add(UserMessage(value));
    state = state.copyWith(messages: messages, clearAction: true);

    final currentNode = _engine?.currentNode;
    if (currentNode != null && currentNode.answers.isNotEmpty) {
      final next = _engine!.selectAnswer(0);
      if (next == null) {
        _persistProfileFromEngine();
        state = state.copyWith(messages: messages, isComplete: true);
        return;
      }
      _showMagnusMessage(next);
    }
  }

  /// Syncs engine variable map → UserProfile in Riverpod + storage.
  void _persistProfileFromEngine() {
    final vars = engineVariables;
    if (vars.isEmpty) return;

    final notifier = ref.read(userProfileProvider.notifier);
    final current = ref.read(userProfileProvider);

    final name = vars['isim'] ?? vars['ismi'] ?? current.name;
    final ageStr = vars['yas'] ?? vars['yasim'] ?? current.age.toString();
    final gender = vars['cinsiyet'] ?? current.gender;
    final job = vars['meslek'] ?? current.job;
    final marital = vars['medeni_durum'] ?? current.maritalStatus;
    final birthDate = vars['dogum_tarihi'] ?? current.birthDate;
    final birthCity = vars['dogum_sehri'] ?? current.birthCity;

    final zodiac = birthDate != null && birthDate.isNotEmpty
        ? ZodiacCalculator.fromBirthDateString(birthDate)
        : (vars['burc'] ?? current.zodiacSign ?? '');

    final updated = UserProfile(
      name: name.isNotEmpty ? name : current.name,
      age: int.tryParse(ageStr) ?? current.age,
      gender: gender.isNotEmpty ? gender : current.gender,
      job: job.isNotEmpty ? job : current.job,
      maritalStatus: marital.isNotEmpty ? marital : current.maritalStatus,
      birthDate: birthDate?.isNotEmpty == true ? birthDate : current.birthDate,
      birthCity: birthCity?.isNotEmpty == true ? birthCity : current.birthCity,
      zodiacSign: zodiac.isNotEmpty ? zodiac : current.zodiacSign,
      onboardingComplete: true,
    );

    notifier.save(updated);
  }

  void clearPendingAction() {
    state = state.copyWith(clearAction: true);
  }

  /// Profili kaydeder ve onboarding'i tamamlar.
  /// Yalnızca AutoProgressButton tamamlandığında çağrılır.
  void completeOnboarding() {
    _persistProfileFromEngine();
  }

  String _currentInputVariable() {
    final action = state.pendingAction ?? '';
    if (action == 'input_name') return 'isim';
    if (action == 'input_age') return 'yas';
    return '';
  }

  String? _getNodeAction(ResolvedNode resolved) {
    if (resolved.node.answers.length == 1 &&
        resolved.node.answers.first.action != null) {
      final action = resolved.node.answers.first.action!;
      if (action.startsWith('input_') || action == 'auto_complete') {
        return action;
      }
    }
    return null;
  }

  Duration _typingDelayFor(int textLength) {
    final ms = (textLength * 18).clamp(600, 2000);
    return Duration(milliseconds: ms);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
