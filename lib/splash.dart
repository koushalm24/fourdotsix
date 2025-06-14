import 'package:flutter/material.dart';
import 'package:fourdotsix/loader.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {



  @override
  void initState() {
    super.initState();
    goToHome();
  }

    void goToHome()  async{
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>  Loader()));
  }
  @override
  Widget build(BuildContext context) {

    
    return Scaffold(
        body:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/splash.png'),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Score Tracker",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40
                ),
                )
              ],
            ),
          
        
      );
    
  }
}