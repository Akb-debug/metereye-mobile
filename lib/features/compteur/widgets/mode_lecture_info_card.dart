import 'package:flutter/material.dart';
import '../models/mode_lecture.dart';

class ModeLectureInfoCard extends StatelessWidget {
  final ModeLecture mode;

  const ModeLectureInfoCard({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(mode.description),
      ),
    );
  }
}