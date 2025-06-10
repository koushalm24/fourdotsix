import 'package:flutter/material.dart';

class TimelineCircle extends StatelessWidget {
  const TimelineCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        border: Border.all(),
        
        borderRadius: BorderRadius.circular(50),
  
      ),
      child: Center(
        child: Text(
          "0",
          
          style: TextStyle(
            fontSize: 20
          ),
          ),
      ),
    );
  }
}