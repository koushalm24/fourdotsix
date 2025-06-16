// widgets/score_timeline.dart

import 'package:flutter/material.dart';
import 'package:fourdotsix/widgets/timeline_event_item.dart';
import '../models/score_event.dart';

 class ScoreTimeline extends StatelessWidget {
    final List<ScoreEvent> timeLineHistory;

    const ScoreTimeline({super.key, required this.timeLineHistory});

    @override
    Widget build(BuildContext context) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 24,
          runSpacing: 10,
          children: timeLineHistory
              .map((event) => TimelineEventItem(event: event))
              .toList(),
        ),
      );
    }
  }

