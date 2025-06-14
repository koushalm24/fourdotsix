import 'package:flutter/material.dart';
import 'package:fourdotsix/main_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Loader extends StatelessWidget {
   final Future<Box> _openBoxFuture = Hive.openBox('scoreBox');
   Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _openBoxFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(debugShowCheckedModeBanner: false, home: MainScreen());
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
      },
    );
  }
}