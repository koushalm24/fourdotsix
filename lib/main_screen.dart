import 'package:flutter/material.dart';
import 'package:fourdotsix/widgets/timeline_circle.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return const Home();
  }
}

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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int totalRuns = 0;
  int totalBalls = 0;
  int dotBalls = 0;
  int wickets = 0;
  bool allOut = false;
  List<ScoreEvent> history = [];
  List<ScoreEvent> timeLinehistory = [];

  final scoreBox = Hive.box("scoreBox");

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  void loadSavedData() {
    totalRuns = scoreBox.get('runs', defaultValue: 0);
    totalBalls = scoreBox.get("balls", defaultValue: 0);
    dotBalls = scoreBox.get("dots", defaultValue: 0);
    wickets = scoreBox.get("wickets", defaultValue: 0);
    allOut = scoreBox.get("allout", defaultValue: false);

    final loaded = scoreBox.get("history", defaultValue: []) as List<dynamic>;
    history = loaded
        .map((e) => ScoreEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Only timeline of current over
    int ballsInCurrentOver = totalBalls % 6;
    timeLinehistory = history.reversed
        .takeWhile((event) => (ballsInCurrentOver--) > 0)
        .toList()
        .reversed
        .toList();

    setState(() {});
  }

  void saveData() {
    scoreBox.put('runs', totalRuns);
    scoreBox.put('balls', totalBalls);
    scoreBox.put('dots', dotBalls);
    scoreBox.put('wickets', wickets);
    scoreBox.put('allout', allOut);

    final jsonHistory = history.map((e) => e.toJson()).toList();
    scoreBox.put('history', jsonHistory);
  }

  void addEvent(ScoreEvent event) {
    if (totalBalls % 6 == 0 && totalBalls > 0) {
      timeLinehistory.clear(); // Reset the timeline
    }

    if (allOut) return;

    setState(() {
      history.add(event);
      timeLinehistory.add(event);

      switch (event.type) {
        case EventType.run:
        case EventType.four:
        case EventType.six:
          totalRuns += event.runs;
          totalBalls++;
          break;
        case EventType.dot:
          dotBalls++;
          totalBalls++;
          break;
        case EventType.wicket:
          wickets++;
          dotBalls++;
          totalBalls++;
          if (wickets >= 10) {
            allOut = true;
          }

          break;
        case EventType.wide:
        case EventType.noBall:
          totalRuns++;
          break;
        case EventType.undo:
        case EventType.overComplete:
          break;
      }

      saveData();
    });
  }

  void undoLast() {
    if (history.isEmpty) return;
    final last = history.removeLast();

    if (timeLinehistory.isNotEmpty) timeLinehistory.removeLast();

    setState(() {
      switch (last.type) {
        case EventType.run:
        case EventType.four:
        case EventType.six:
          totalRuns -= last.runs;
          totalBalls--;
          break;
        case EventType.dot:
          dotBalls--;
          totalBalls--;
          break;
        case EventType.wicket:
          dotBalls--;
          wickets--;
          totalBalls--;
          if (wickets < 10) {
            allOut = false;
          }
          break;
        case EventType.wide:
        case EventType.noBall:
          totalRuns--;
          break;
        case EventType.undo:
        case EventType.overComplete:
          break;
      }
      saveData();
    });
  }

  void showRunPopup() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          for (var i in [1, 2, 3])
            ListTile(
              title: Text("$i Run${i > 1 ? 's' : ''}"),
              onTap: () {
                Navigator.pop(context);
                addEvent(ScoreEvent(type: EventType.run, runs: i));
              },
            ),
          ListTile(
            title: Text("4 Runs"),
            onTap: () {
              Navigator.pop(context);
              addEvent(ScoreEvent(type: EventType.four, runs: 4));
            },
          ),
          ListTile(
            title: Text("6 Runs"),
            onTap: () {
              Navigator.pop(context);
              addEvent(ScoreEvent(type: EventType.six, runs: 6));
            },
          ),
          ListTile(
            title: Text("Wide Ball"),
            onTap: () {
              Navigator.pop(context);
              addEvent(ScoreEvent(type: EventType.wide));
            },
          ),
          ListTile(
            title: Text("No Ball"),
            onTap: () {
              Navigator.pop(context);
              addEvent(ScoreEvent(type: EventType.noBall));
            },
          ),
          ListTile(
            title: Text("Wicket"),
            onTap: () {
              Navigator.pop(context);
              addEvent(ScoreEvent(type: EventType.wicket));
            },
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(
    BuildContext context,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Score'),
        content: Text('Are you sure you want to reset the score?'),
        actions: [
         
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onConfirm(); // Run the actual reset logic
            },
            child: Text('Yes'),
          ),
           TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void resetData() {
    setState(() {
      totalRuns = 0;
      totalBalls = 0;
      dotBalls = 0;
      wickets = 0;
      history.clear();
      timeLinehistory.clear();
      saveData();
    });
  }

  String get overString => "${totalBalls ~/ 6}.${totalBalls % 6}";
  double get runRate => totalBalls == 0 ? 0 : (totalRuns * 6) / totalBalls;
  double get dotPercentage =>
      totalBalls == 0 ? 0 : (dotBalls * 100) / totalBalls;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      _showResetConfirmationDialog(context, () {
                        resetData();
                      });
                    },
                    child: const Text(
                      "Reset Score",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Score : $totalRuns / $wickets",
                        style: const TextStyle(fontSize: 50),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 20,
                    children: [
                      Text(
                        "Overs : $overString ",
                        style: TextStyle(fontSize: 30),
                      ),
                      Text(
                        "RR : ${runRate.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "Total Dots: $dotBalls (${dotPercentage.toStringAsFixed(1)}%)",
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: ScoreTimeline(timeLineHistory: timeLinehistory),
                    ),
                  ),

                  Text(
                    allOut ? "Team is All Out" : "",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(25.0),
        child: Row(
          spacing: 10,
          children: [
            SizedBox(
              width: media.width * 0.27,
              child: ElevatedButton(
                onPressed: undoLast,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                child: Text(
                  "UNDO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: media.width * 0.05,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: media.width * 0.27,
              child: ElevatedButton(
                onPressed: () => addEvent(ScoreEvent(type: EventType.dot)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text(
                  "DOT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: media.width * 0.05,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: media.width * 0.27,
              child: ElevatedButton(
                onPressed: showRunPopup,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  "RUNS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: media.width * 0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
