enum EventType { run, four, six, dot, wide, noBall, wicket, undo, overComplete }

  class ScoreEvent {
    final EventType type;
    final int runs;
    final DateTime timestamp;

    ScoreEvent({required this.type, this.runs = 0, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

    Map<String, dynamic> toJson() => {
      'type': type.name,
      'runs': runs,
      'timestamp': timestamp.toIso8601String(),
    };

    factory ScoreEvent.fromJson(Map<String, dynamic> json) {
      return ScoreEvent(
        type: EventType.values.firstWhere((e) => e.name == json['type']),
        runs: json['runs'],
        timestamp: DateTime.parse(json['timestamp']),
      );
    }
  }