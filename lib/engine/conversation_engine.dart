import '../data/models/chat_node.dart';
import '../data/models/user_profile.dart';
import '../core/utils/variable_replacer.dart';

/// The core conversation state machine.
/// Equivalent of Unity's ChatManager + ModSohbetManager combined.
class ConversationEngine {
  final ConversationFlow flow;
  final UserProfile profile;

  /// Ekran dili İngilizce mi? → messages_en / labels_en seçimi için.
  final bool isEn;

  /// Runtime variable map — starts from user profile, grows as conversation progresses.
  final Map<String, String> _variables = {};

  /// History of (node, selected answer index) pairs.
  final List<EngineStep> _history = [];

  ChatNode? _currentNode;
  bool _isComplete = false;

  ConversationEngine({required this.flow, required this.profile, this.isEn = false}) {
    _variables.addAll(profile.toVariableMap());
  }

  // ─── State ──────────────────────────────────────────────────────────────

  ChatNode? get currentNode => _currentNode;
  bool get isComplete => _isComplete;
  bool get isStarted => _currentNode != null;
  List<EngineStep> get history => List.unmodifiable(_history);
  Map<String, String> get variables => Map.unmodifiable(_variables);

  // ─── Start ──────────────────────────────────────────────────────────────

  /// Returns the resolved text for the first node.
  ResolvedNode start() {
    _currentNode = flow.startNode;
    _applySetVariables(_currentNode!.setVariables);
    return _resolve(_currentNode!);
  }

  // ─── Select answer ───────────────────────────────────────────────────────

  /// Call when user taps an answer button.
  /// Returns the next ResolvedNode, or null if conversation is complete.
  ResolvedNode? selectAnswer(int answerIndex) {
    final node = _currentNode;
    if (node == null) return null;

    final answer = node.answers[answerIndex];

    // Apply answer's variable assignments
    _applySetVariables(answer.setVariables);

    // Record history
    _history.add(EngineStep(nodeId: node.id, selectedAnswerIndex: answerIndex));

    // Handle special actions
    if (answer.action != null) {
      _handleAction(answer.action!);
    }

    // Navigate to next node
    if (answer.nextNodeId == null) {
      _isComplete = true;
      return null;
    }

    final nextNode = _findNextNode(answer.nextNodeId!);
    if (nextNode == null) {
      _isComplete = true;
      return null;
    }

    _currentNode = nextNode;
    _applySetVariables(nextNode.setVariables);

    if (nextNode.isFortuneTrigger) {
      _isComplete = true;
    }

    return _resolve(nextNode);
  }

  // ─── Variable operations ──────────────────────────────────────────────────

  void setVariable(String key, String value) {
    _variables[key] = value;
  }

  String getVariable(String key, {String defaultValue = ''}) {
    return _variables[key] ?? defaultValue;
  }

  void _applySetVariables(List<VariableAssignment> assignments) {
    for (final a in assignments) {
      switch (a.op) {
        case AssignOp.set:
          _variables[a.variable] = a.value;
        case AssignOp.add:
          final current = double.tryParse(_variables[a.variable] ?? '0') ?? 0;
          final delta = double.tryParse(a.value) ?? 0;
          _variables[a.variable] = (current + delta).toString();
        case AssignOp.subtract:
          final current = double.tryParse(_variables[a.variable] ?? '0') ?? 0;
          final delta = double.tryParse(a.value) ?? 0;
          _variables[a.variable] = (current - delta).toString();
        case AssignOp.multiply:
          final current = double.tryParse(_variables[a.variable] ?? '0') ?? 0;
          final factor = double.tryParse(a.value) ?? 1;
          _variables[a.variable] = (current * factor).toString();
        case AssignOp.divide:
          final current = double.tryParse(_variables[a.variable] ?? '0') ?? 0;
          final divisor = double.tryParse(a.value) ?? 1;
          if (divisor != 0) {
            _variables[a.variable] = (current / divisor).toString();
          }
      }
    }
  }

  // ─── Condition checking ───────────────────────────────────────────────────

  bool _meetsConditions(List<VariableCondition> conditions) {
    for (final c in conditions) {
      final current = _variables[c.variable] ?? '';
      if (!_checkCondition(current, c.value, c.op)) return false;
    }
    return true;
  }

  bool _checkCondition(String current, String target, ConditionOp op) {
    switch (op) {
      case ConditionOp.eq:
        return current == target;
      case ConditionOp.neq:
        return current != target;
      case ConditionOp.contains:
        return current.contains(target);
      case ConditionOp.gt:
        return (double.tryParse(current) ?? 0) > (double.tryParse(target) ?? 0);
      case ConditionOp.lt:
        return (double.tryParse(current) ?? 0) < (double.tryParse(target) ?? 0);
      case ConditionOp.gte:
        return (double.tryParse(current) ?? 0) >= (double.tryParse(target) ?? 0);
      case ConditionOp.lte:
        return (double.tryParse(current) ?? 0) <= (double.tryParse(target) ?? 0);
    }
  }

  // ─── Node resolution ──────────────────────────────────────────────────────

  ChatNode? _findNextNode(String nodeId) {
    final node = flow.node(nodeId);
    if (node == null) return null;
    // Check conditions
    if (node.conditions.isNotEmpty && !_meetsConditions(node.conditions)) {
      return null;
    }
    return node;
  }

  ResolvedNode _resolve(ChatNode node) {
    final message = _resolveMessage(node);
    final answers = node.answers.map((a) => _resolveAnswer(a)).toList();
    return ResolvedNode(
      node: node,
      resolvedMessage: message,
      resolvedAnswers: answers,
    );
  }

  String _resolveMessage(ChatNode node) {
    final variation = VariableReplacer.pickVariation(
      node.messagesFor(isEn),
      seed: profile.name,
    );
    return VariableReplacer.replace(variation, _variables);
  }

  String _resolveAnswer(ChatAnswer answer) {
    final variation = VariableReplacer.pickVariation(
      answer.labelsFor(isEn),
      seed: profile.name,
    );
    return VariableReplacer.replace(variation, _variables);
  }

  void _handleAction(String action) {
    // Action handling deferred to the UI layer via ResolvedNode.action
  }
}

// ─── Output types ─────────────────────────────────────────────────────────────

class ResolvedNode {
  final ChatNode node;
  final String resolvedMessage;
  final List<String> resolvedAnswers;

  const ResolvedNode({
    required this.node,
    required this.resolvedMessage,
    required this.resolvedAnswers,
  });

  bool get hasAnswers => resolvedAnswers.isNotEmpty;
  bool get isFortuneTrigger => node.isFortuneTrigger;
  String? get action => node.answers.isNotEmpty ? null : null;
}

class EngineStep {
  final String nodeId;
  final int selectedAnswerIndex;
  const EngineStep({required this.nodeId, required this.selectedAnswerIndex});
}
