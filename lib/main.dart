// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:fourdotsix/widgets/timeline_circle.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<Box> _openBoxFuture = Hive.openBox('scoreBox');
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _openBoxFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(debugShowCheckedModeBanner: false, home: Home());
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
      },
    );
  }
}

class ScoreTimeline extends StatelessWidget {

  final List<ScoreEvent> timeLineHistory;

  const ScoreTimeline({
    super.key,
    required this.timeLineHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...timeLineHistory.map(
          (event) => TimelineEventItem(
            event: event,
            timeLineHistory: timeLineHistory,
          ),
        ),
      ],
    );
  }
}

class TimelineEventItem extends StatelessWidget {
  final ScoreEvent event;
  final List<ScoreEvent> timeLineHistory;

  const TimelineEventItem({
    super.key,
    required this.timeLineHistory,
    required this.event,
   
  });

  @override
  Widget build(BuildContext context) {
    return  Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          spacing: 10,
          children: [
            
                const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getEventColor(event.type),
                shape: BoxShape.circle,
                
              ),
              child: event.type == EventType.dot
        ? Icon(Icons.park, size: 20, color: Colors.white)
        : TimelineCircle(
            data: _getEventDescription(event).toString(),
          ),
            ),
          ],
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
        return Colors.white;
      case EventType.undo:
        return Colors.blue;
      default:
        return Colors.white;
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

enum EventType { run,four, six, dot, wide, noBall, wicket, undo, overComplete }

class ScoreEvent {
  final EventType type;
  final int runs;
  final DateTime timestamp;

  ScoreEvent({required this.type, this.runs = 0, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
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
    setState(() {});
  }

  void saveData() {
    scoreBox.put('runs', totalRuns);
    scoreBox.put('balls', totalBalls);
    scoreBox.put('dots', dotBalls);
  }

  void addEvent(ScoreEvent event) {
    if (totalBalls % 6 == 0 && totalBalls > 0) {
        timeLinehistory.clear(); // Reset the timeline
      }
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
        case EventType.wicket:
          dotBalls++;
          totalBalls++;
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
    if (history.isEmpty ) return;
    final last = history.removeLast();
    
    if (timeLinehistory.isNotEmpty ) timeLinehistory.removeLast();
   
    setState(() {
      switch (last.type) {
        case EventType.run:
        case EventType.four:
        case EventType.six:
          totalRuns -= last.runs;
          totalBalls--;
          break;
        case EventType.dot:
        case EventType.wicket:
          dotBalls--;
          totalBalls--;
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
          for (var i in [1, 2, 3,])
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

  void resetData() {
    setState(() {
      totalRuns = 0;
      totalBalls = 0;
      dotBalls = 0;
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
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed: resetData,
                    child: const Text(
                      "Reset Score",
                      style: TextStyle(color: Colors.red, fontSize: 20),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Score : $totalRuns",
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

                  Row(
                    spacing: 20,
                    children: [
                      ScoreTimeline(
                        timeLineHistory: timeLinehistory,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: undoLast,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                child: Text(
                  "UNDO",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () => addEvent(ScoreEvent(type: EventType.dot)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text(
                  "DOT",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: showRunPopup,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  "RUNS",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
