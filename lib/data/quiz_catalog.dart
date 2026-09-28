import 'package:flutter/material.dart';

import '../models/learning_game_model.dart';

final List<LearningGameModel> quizCatalog = <LearningGameModel>[
  const LearningGameModel(
    gameId: 'math_quiz',
    title: 'Math Quiz',
    subtitle: 'Quick sums and number sense',
    icon: Icons.calculate_outlined,
    questions: <QuizQuestion>[
      QuizQuestion(
        prompt: 'What is 7 + 5?',
        choices: <String>['10', '11', '12', '13'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'What is 9 − 4?',
        choices: <String>['3', '5', '6', '4'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'What is 3 × 6?',
        choices: <String>['12', '16', '18', '21'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'What is 20 ÷ 5?',
        choices: <String>['2', '4', '5', '6'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Which number is even?',
        choices: <String>['11', '15', '18', '21'],
        correctIndex: 2,
      ),
    ],
  ),
  const LearningGameModel(
    gameId: 'spelling_quiz',
    title: 'Spelling Quiz',
    subtitle: 'Pick the correctly spelled word',
    icon: Icons.spellcheck_rounded,
    questions: <QuizQuestion>[
      QuizQuestion(
        prompt: 'Which spelling is correct?',
        choices: <String>['Friens', 'Friends', 'Frends', 'Freinds'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Choose the right word for a place to learn.',
        choices: <String>['Scool', 'Skool', 'School', 'Schoole'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'Which word means a yellow fruit?',
        choices: <String>['Banan', 'Banana', 'Bannana', 'Bananna'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Pick the correct spelling.',
        choices: <String>['Becuase', 'Because', 'Becaus', 'Becouse'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Which word is spelled correctly?',
        choices: <String>['Beautiful', 'Beutiful', 'Beautifull', 'Buetiful'],
        correctIndex: 0,
      ),
    ],
  ),
  const LearningGameModel(
    gameId: 'knowledge_quiz',
    title: 'General Knowledge',
    subtitle: 'Curious facts for bright minds',
    icon: Icons.public_outlined,
    questions: <QuizQuestion>[
      QuizQuestion(
        prompt: 'How many days are in a week?',
        choices: <String>['5', '6', '7', '8'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'Which planet do we live on?',
        choices: <String>['Mars', 'Earth', 'Venus', 'Jupiter'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'What do bees make?',
        choices: <String>['Milk', 'Honey', 'Bread', 'Juice'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Which of these is a primary colour?',
        choices: <String>['Green', 'Purple', 'Blue', 'Pink'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'How many hours are in a day?',
        choices: <String>['12', '20', '24', '30'],
        correctIndex: 2,
      ),
    ],
  ),
];
