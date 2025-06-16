
import 'package:flutter/material.dart';
import 'package:fourdotsix/models/score_event.dart';
import 'package:fourdotsix/widgets/timeline_circle.dart';

class TimelineEventItem extends StatelessWidget {
    final ScoreEvent event;

    const TimelineEventItem({super.key, required this.event});

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: CircleAvatar(
          radius: 20,

          backgroundColor: _getEventColor(event.type),
          foregroundColor: Colors.white,

          child: event.type == EventType.dot
              ? Icon(Icons.park, size: 20, color: Colors.white)
              : TimelineCircle(data: _getEventDescription(event).toString()),
        ),
      );
    }

    Color _getEventColor(EventType type) {
      switch (type) {
        case EventType.six:
          return Colors.pink;
        case EventType.four:
          return Colors.yellow;
        case EventType.dot:
          return Colors.green;
        case EventType.wicket:
          return Colors.red;
        case EventType.run:
          return Colors.black;
        case EventType.undo:
          return Colors.blue;
        default:
          return Colors.black;
      }
    }

    String _getEventDescription(ScoreEvent event) {
      switch (event.type) {
        case EventType.run:
          return '${event.runs}';
        case EventType.four:
          return '${event.runs}';
        case EventType.six:
          return '${event.runs}';
        case EventType.dot:
          return '0';
        case EventType.wicket:
          return 'W';
        case EventType.noBall:
          return 'NB';
        case EventType.wide:
          return 'WD';

        default:
          return event.type.toString();
      }
    }
  }