/// Agent Registry: Plug-and-play sub-agent registration system.
///
/// Each sub-agent self-describes its capabilities via the [SubAgent] interface.
/// The [AgentRegistry] maintains the catalog and provides a routing manifest
/// that the Master Manager's LLM uses to classify intents.

import 'agent_contracts.dart';

/// Every sub-agent must implement this interface.
/// Sub-agents are SILENT TOOL EXECUTORS — they never produce conversational output.
abstract class SubAgent {
  /// Unique identifier for this agent (e.g., 'retail', 'billing', 'finance')
  String get id;

  /// Human-readable display name (e.g., 'Retail & Stock Agent')
  String get displayName;

  /// Description of what this agent handles — used by the Manager LLM for routing decisions.
  /// Should be written as if explaining to another AI what this agent's expertise is.
  String get description;

  /// The Genkit tool names this agent is authorized to use.
  /// These form the agent's sandbox — it cannot access tools outside this list.
  List<String> get toolNames;

  /// Execute a task delegated by the Master Manager.
  /// 
  /// STRICT RULES:
  /// 1. Must invoke at least one tool or return [AgentResponse.missingParams]
  /// 2. Must NOT produce conversational text — only factual summaries for the Manager
  /// 3. Is completely STATELESS — no memory of previous calls
  /// 4. Returns structured data via [AgentResponse]
  Future<AgentResponse> execute(AgentRequest request);
}

/// Central registry that holds all available sub-agents.
/// The Master Manager queries this to build its routing manifest.
class AgentRegistry {
  final Map<String, SubAgent> _agents = {};

  /// Register a new sub-agent. Call this during server bootstrap.
  void register(SubAgent agent) {
    _agents[agent.id] = agent;
    print('[AgentRegistry] Registered agent: ${agent.id} (${agent.displayName}) — ${agent.toolNames.length} tools');
  }

  /// Get a specific agent by ID
  SubAgent? getAgent(String id) => _agents[id];

  /// Get all registered agents
  List<SubAgent> get all => _agents.values.toList();

  /// Get all registered agent IDs
  List<String> get agentIds => _agents.keys.toList();

  /// Generate the routing manifest that the Manager's LLM uses for intent classification.
  /// This is injected into the Manager's system prompt so it knows what agents are available.
  String getRoutingManifest() {
    if (_agents.isEmpty) return 'No agents registered.';

    final buffer = StringBuffer();
    for (final agent in _agents.values) {
      buffer.writeln('- Agent "${agent.id}" (${agent.displayName}): ${agent.description}');
      buffer.writeln('  Tools: ${agent.toolNames.join(", ")}');
    }
    return buffer.toString().trimRight();
  }

  /// Validate that all registered agents have unique IDs and non-overlapping tool sets
  List<String> validate() {
    final errors = <String>[];
    final allTools = <String, String>{};  // toolName -> owning agentId

    for (final agent in _agents.values) {
      for (final tool in agent.toolNames) {
        if (allTools.containsKey(tool)) {
          errors.add('Tool "$tool" is registered by both "${allTools[tool]}" and "${agent.id}" — tools must not overlap across agents.');
        } else {
          allTools[tool] = agent.id;
        }
      }
    }

    return errors;
  }
}
