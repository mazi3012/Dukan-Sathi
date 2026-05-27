/// Typed communication contracts between Master Manager and Sub-Agents.
/// 
/// These envelopes ensure every agent speaks the same language,
/// eliminating ad-hoc map parsing and making the system type-safe.

/// Status codes a sub-agent can return
enum AgentStatus {
  success,
  errorMissingParams,
  errorToolFailed,
  errorNotMyDomain,
}

/// What the Master Manager sends TO a sub-agent
class AgentRequest {
  final String taskDescription;      // What the Manager wants done (natural language instruction)
  final String originalUserInput;    // The shopkeeper's raw text
  final String shopId;
  final String userId;
  final Map<String, dynamic>? extractedParameters;  // Pre-parsed hints from Manager

  const AgentRequest({
    required this.taskDescription,
    required this.originalUserInput,
    required this.shopId,
    required this.userId,
    this.extractedParameters,
  });

  Map<String, dynamic> toJson() => {
    'taskDescription': taskDescription,
    'originalUserInput': originalUserInput,
    'shopId': shopId,
    'userId': userId,
    'extractedParameters': extractedParameters,
  };
}

/// A UI card payload to be rendered on the client
class CardPayload {
  final String type;                 // 'invoice', 'batch', 'analytics_summary', etc.
  final Map<String, dynamic> data;

  const CardPayload({required this.type, required this.data});

  Map<String, dynamic> toJson() => {
    'type': type,
    ...data,
  };
}

/// What a sub-agent returns TO the Master Manager
class AgentResponse {
  final AgentStatus status;
  final String? summaryForManager;          // Short factual summary (NOT for the user — the Manager rewrites this)
  final Map<String, dynamic>? toolResult;   // Raw structured data from tool execution
  final CardPayload? card;                  // Optional UI card to render on client
  final List<String>? missingFields;        // Populated when status == errorMissingParams

  const AgentResponse({
    required this.status,
    this.summaryForManager,
    this.toolResult,
    this.card,
    this.missingFields,
  });

  /// Quick constructor for successful tool execution
  factory AgentResponse.success({
    required String summary,
    Map<String, dynamic>? toolResult,
    CardPayload? card,
  }) => AgentResponse(
    status: AgentStatus.success,
    summaryForManager: summary,
    toolResult: toolResult,
    card: card,
  );

  /// Quick constructor for missing parameters
  factory AgentResponse.missingParams(List<String> fields) => AgentResponse(
    status: AgentStatus.errorMissingParams,
    summaryForManager: 'Missing required parameters: ${fields.join(", ")}',
    missingFields: fields,
  );

  /// Quick constructor for tool execution failure
  factory AgentResponse.toolFailed(String error) => AgentResponse(
    status: AgentStatus.errorToolFailed,
    summaryForManager: 'Tool execution failed: $error',
  );

  /// Quick constructor when the request doesn't belong to this agent's domain
  factory AgentResponse.notMyDomain() => AgentResponse(
    status: AgentStatus.errorNotMyDomain,
    summaryForManager: 'This request does not fall within my domain.',
  );
}

/// The routing decision made by the Master Manager's intent classifier
class RoutingDecision {
  final bool isChitchat;
  final String? chitchatReply;
  final Map<String, String> agentTasks;   // agentId -> task description

  const RoutingDecision({
    this.isChitchat = false,
    this.chitchatReply,
    this.agentTasks = const {},
  });

  List<String> get targetAgentIds => agentTasks.keys.toList();
  bool get requiresAgents => !isChitchat && agentTasks.isNotEmpty;
}
