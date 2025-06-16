// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/score_event.dart';
import '../widgets/score_timeline.dart';

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
    scoreBox.put('history', history.map((e) => e.toJson()).toList());
  }

  void addEvent(ScoreEvent event) {
    if (totalBalls % 6 == 0 && totalBalls > 0) timeLinehistory.clear();
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
          dotBalls++;
          totalBalls++;
          wickets++;
          if (wickets >= 10) allOut = true;
          break;
        case EventType.wide:
        case EventType.noBall:
          totalRuns++;
          break;
        default:
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
          totalBalls--;
          wickets--;
          if (wickets < 10) allOut = false;
          break;
        case EventType.wide:
        case EventType.noBall:
          totalRuns--;
          break;
        default:
          break;
      }
      saveData();
    });
  }

  void resetData() {
    setState(() {
      totalRuns = 0;
      totalBalls = 0;
      dotBalls = 0;
      wickets = 0;
      allOut = false;
      history.clear();
      timeLinehistory.clear();
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

  String get overString => "${totalBalls ~/ 6}.${totalBalls % 6}";
  double get runRate => totalBalls == 0 ? 0 : (totalRuns * 6) / totalBalls;
  double get dotPercentage =>
      totalBalls == 0 ? 0 : (dotBalls * 100) / totalBalls;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Reset Score'),
                      content:
                          Text('Are you sure you want to reset the score?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            resetData();
                          },
                          child: Text('Yes'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                      ],
                    ),
                  );
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
                children: [
                  Text("Overs : $overString ", style: TextStyle(fontSize: 30)),
                  Text("RR : ${runRate.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 30)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Total Dots: $dotBalls (${dotPercentage.toStringAsFixed(1)}%)",
              ),
              const SizedBox(height: 20),
              ScoreTimeline(timeLineHistory: timeLinehistory),
              const Spacer(),
              if (allOut)
                Text(
                  "Team is All Out",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(25.0),
        child: Row(
          children: [
            SizedBox(
              width: media.width * 0.27,
              child: ElevatedButton(
                onPressed: undoLast,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                child: Text("UNDO",
                    style: TextStyle(
                        color: Colors.white, fontSize: media.width * 0.05)),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: media.width * 0.27,
              child: ElevatedButton(
                onPressed: () => addEvent(ScoreEvent(type: EventType.dot)),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text("DOT",
                    style: TextStyle(
                        color: Colors.white, fontSize: media.width * 0.05)),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: media.width * 0.27,
              child: ElevatedButton(
                onPressed: showRunPopup,
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text("RUNS",
                    style: TextStyle(
                        color: Colors.white, fontSize: media.width * 0.05)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
