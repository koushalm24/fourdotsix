// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:fourdotsix/widgets/timeline_circle.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  runApp( MyApp());
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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Home(),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
      },
    );
  }

}

enum EventType { run, dot, wide, noBall }

class ScoreEvent {
  final EventType type;
  final int runs;

  ScoreEvent({required this.type, this.runs = 0});
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
    setState(() {
      history.add(event);
      switch (event.type) {
        case EventType.run:
          totalRuns += event.runs;
          totalBalls++;
          break;
        case EventType.dot:
          dotBalls++;
          totalBalls++;
          break;
        case EventType.wide:
        case EventType.noBall:
          totalRuns++;
          break;
      }
      saveData();
    });
  }

  void undoLast() {
    if (history.isEmpty) return;
    final last = history.removeLast();
    setState(() {
      switch (last.type) {
        case EventType.run:
          totalRuns -= last.runs;
          totalBalls--;
          break;
        case EventType.dot:
          dotBalls--;
          totalBalls--;
          break;
        case EventType.wide:
        case EventType.noBall:
          totalRuns--;
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
          for (var i in [1, 2, 3, 4, 6])
            ListTile(
              title: Text("$i Run${i > 1 ? 's' : ''}"),
              onTap: () {
                Navigator.pop(context);
                addEvent(ScoreEvent(type: EventType.run, runs: i));
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
                      TimelineCircle(),
                      TimelineCircle(),
                      TimelineCircle(),
                      TimelineCircle(),
                      TimelineCircle(),
                      TimelineCircle(),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan,
                ),
                child: Text("UNDO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () => addEvent(ScoreEvent(type: EventType.dot)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text("DOT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: showRunPopup,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text("RUNS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),),
              ),
            ),
          ],
               ),
       ),
    );
  }
}
