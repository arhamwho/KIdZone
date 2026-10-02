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
      QuizQuestion(
        prompt: 'What is 8 + 8?',
        choices: <String>['14', '16', '18', '20'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'What is 15 − 6?',
        choices: <String>['7', '8', '9', '11'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'What is 4 × 5?',
        choices: <String>['16', '20', '24', '25'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'What is 12 ÷ 3?',
        choices: <String>['2', '3', '4', '6'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'Which is the largest?',
        choices: <String>['19', '21', '17', '20'],
        correctIndex: 1,
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
      QuizQuestion(
        prompt: 'Choose the correct spelling.',
        choices: <String>['Tommorow', 'Tomorrow', 'Tommorrow', 'Tomorow'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Which word is right?',
        choices: <String>['Famly', 'Family', 'Familey', 'Famaly'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Pick the correctly spelled animal.',
        choices: <String>['Elefant', 'Elephant', 'Elephent', 'Eliphant'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Which spelling is correct?',
        choices: <String>['Wensday', 'Wednesday', 'Wedensday', 'Wendesday'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'Choose the right word.',
        choices: <String>['Frendly', 'Friendly', 'Friendley', 'Frendely'],
        correctIndex: 1,
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
      QuizQuestion(
        prompt: 'What colour is the sky on a clear day?',
        choices: <String>['Green', 'Blue', 'Red', 'Yellow'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'How many legs does a spider have?',
        choices: <String>['4', '6', '8', '10'],
        correctIndex: 2,
      ),
      QuizQuestion(
        prompt: 'Which season comes after winter?',
        choices: <String>['Autumn', 'Spring', 'Summer', 'Winter'],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: 'What do we use to tell the time?',
        choices: <String>['A clock', 'A spoon', 'A shoe', 'A book'],
        correctIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Which of these is a fruit?',
        choices: <String>['Carrot', 'Apple', 'Bread', 'Cheese'],
        correctIndex: 1,
      ),
    ],
  ),
];
