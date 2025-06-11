import 'package:flutter/material.dart';

class TimelineCircle extends StatelessWidget {
  final String data;
  const TimelineCircle({super.key, required this.data});

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
          data,
          
          style: TextStyle(
            fontSize: 18,
            
          ),
          ),
      ),
    );
  }
}