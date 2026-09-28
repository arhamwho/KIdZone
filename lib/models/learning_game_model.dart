import 'package:flutter/material.dart';

class LearningGameModel {
  const LearningGameModel({
    required this.gameId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.questions,
  });

  final String gameId;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<QuizQuestion> questions;
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;
}
