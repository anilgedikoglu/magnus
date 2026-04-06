// Dart equivalent of Unity's OnlineSohbetData / Sohbet model.
// Each node is one step in the conversation tree.

enum BubbleColorTheme { color1, color2, color3, color4, color5 }

enum AnswerLayout { vertical, horizontal } // altAlta / yanYana

class ChatNode {
  final String id;

  /// Magnus's message text (may contain {{variable}} placeholders).
  /// Multiple variations — one is picked randomly at runtime.
  final List<String> messages;

  /// Answer options shown to the user.
  final List<ChatAnswer> answers;

  /// Which bubble color gradient to use.
  final BubbleColorTheme bubbleColor;

  /// Answer button layout.
  final AnswerLayout answerLayout;

  /// Variables to SET when this node is displayed.
  final List<VariableAssignment> setVariables;

  /// Conditions required for this node to be shown.
  final List<VariableCondition> conditions;

  /// If true, this node ends the conversation and triggers fortune generation.
  final bool isFortuneTrigger;

  /// Optional image asset key shown in the bubble.
  final String? imageAsset;

  const ChatNode({
    required this.id,
    required this.messages,
    this.answers = const [],
    this.bubbleColor = BubbleColorTheme.color1,
    this.answerLayout = AnswerLayout.vertical,
    this.setVariables = const [],
    this.conditions = const [],
    this.isFortuneTrigger = false,
    this.imageAsset,
  });

  factory ChatNode.fromJson(Map<String, dynamic> json) {
    return ChatNode(
      id: json['id'] as String,
      messages: List<String>.from(json['messages'] as List),
      answers: (json['answers'] as List? ?? [])
          .map((a) => ChatAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      bubbleColor: BubbleColorTheme.values.firstWhere(
        (e) => e.name == (json['bubbleColor'] ?? 'color1'),
        orElse: () => BubbleColorTheme.color1,
      ),
      answerLayout: (json['answerLayout'] ?? 'vertical') == 'horizontal'
          ? AnswerLayout.horizontal
          : AnswerLayout.vertical,
      setVariables: (json['setVariables'] as List? ?? [])
          .map((v) => VariableAssignment.fromJson(v as Map<String, dynamic>))
          .toList(),
      conditions: (json['conditions'] as List? ?? [])
          .map((c) => VariableCondition.fromJson(c as Map<String, dynamic>))
          .toList(),
      isFortuneTrigger: json['isFortuneTrigger'] as bool? ?? false,
      imageAsset: json['imageAsset'] as String?,
    );
  }
}

// ─── Answer / Choice ─────────────────────────────────────────────────────────

class ChatAnswer {
  /// Button label variations — one is picked randomly.
  final List<String> labels;

  /// ID of the next ChatNode to navigate to.
  final String? nextNodeId;

  /// Variables to SET when this answer is selected.
  final List<VariableAssignment> setVariables;

  /// Optional special action key (e.g. 'open_camera', 'generate_fortune').
  final String? action;

  const ChatAnswer({
    required this.labels,
    this.nextNodeId,
    this.setVariables = const [],
    this.action,
  });

  factory ChatAnswer.fromJson(Map<String, dynamic> json) {
    return ChatAnswer(
      labels: List<String>.from(json['labels'] as List),
      nextNodeId: json['nextNodeId'] as String?,
      setVariables: (json['setVariables'] as List? ?? [])
          .map((v) => VariableAssignment.fromJson(v as Map<String, dynamic>))
          .toList(),
      action: json['action'] as String?,
    );
  }
}

// ─── Variable system ──────────────────────────────────────────────────────────

enum AssignOp { set, add, subtract, multiply, divide }

class VariableAssignment {
  final String variable;
  final String value;
  final AssignOp op;

  const VariableAssignment({
    required this.variable,
    required this.value,
    this.op = AssignOp.set,
  });

  factory VariableAssignment.fromJson(Map<String, dynamic> json) {
    return VariableAssignment(
      variable: json['variable'] as String,
      value: json['value'].toString(),
      op: AssignOp.values.firstWhere(
        (e) => e.name == (json['op'] ?? 'set'),
        orElse: () => AssignOp.set,
      ),
    );
  }
}

enum ConditionOp { eq, neq, gt, lt, gte, lte, contains }

class VariableCondition {
  final String variable;
  final String value;
  final ConditionOp op;

  const VariableCondition({
    required this.variable,
    required this.value,
    this.op = ConditionOp.eq,
  });

  factory VariableCondition.fromJson(Map<String, dynamic> json) {
    return VariableCondition(
      variable: json['variable'] as String,
      value: json['value'].toString(),
      op: ConditionOp.values.firstWhere(
        (e) => e.name == (json['op'] ?? 'eq'),
        orElse: () => ConditionOp.eq,
      ),
    );
  }
}

// ─── Conversation flow ────────────────────────────────────────────────────────

/// A complete conversation module (onboarding, coffee, tarot, etc.)
class ConversationFlow {
  final String id;
  final String title;
  final String startNodeId;
  final Map<String, ChatNode> nodes;

  const ConversationFlow({
    required this.id,
    required this.title,
    required this.startNodeId,
    required this.nodes,
  });

  factory ConversationFlow.fromJson(Map<String, dynamic> json) {
    final nodeList = (json['nodes'] as List)
        .map((n) => ChatNode.fromJson(n as Map<String, dynamic>))
        .toList();
    return ConversationFlow(
      id: json['id'] as String,
      title: json['title'] as String,
      startNodeId: json['startNodeId'] as String,
      nodes: {for (final n in nodeList) n.id: n},
    );
  }

  ChatNode? node(String id) => nodes[id];
  ChatNode get startNode => nodes[startNodeId]!;
}
