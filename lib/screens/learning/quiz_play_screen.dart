import 'package:flutter/material.dart';

import '../../models/learning_game_model.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/game_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_views.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _index = 0;
  int _score = 0;
  int? _picked;
  bool _locked = false;
  bool _done = false;
  bool _saving = false;
  QuizSaveResult? _saved;

  LearningGameModel? get _game => GameService.instance.gameById(widget.gameId);

  Future<void> _finish() async {
    final LearningGameModel? game = _game;
    if (game == null) return;
    setState(() {
      _done = true;
      _saving = true;
    });
    try {
      final String? uid = AuthService.instance.currentFirebaseUser?.uid;
      if (uid == null) return;
      final profile = await FirestoreService.instance.getUserProfile(uid);
      final String? familyId = profile?.familyId;
      if (familyId == null) return;
      _saved = await GameService.instance.saveQuizResult(
        familyId: familyId,
        childId: uid,
        gameId: game.gameId,
        score: _score,
        maxScore: game.questions.length,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your score could not be saved. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LearningGameModel? game = _game;
    if (game == null) {
      return const AppPage(
        title: '',
        child: Column(
          children: <Widget>[
            AppTopBar(title: 'Game'),
            Expanded(
              child: MessageView('That game could not be found.'),
            ),
          ],
        ),
      );
    }

    if (_done) {
      final bool perfect = _score == game.questions.length;
      final int awarded = _saved?.awardedPoints ?? 0;
      final int best = _saved?.bestScore ?? _score;
      return AppPage(
        title: '',
        tint: UserRole.child.tint,
        child: Column(
          children: <Widget>[
            AppTopBar(title: game.title),
            Expanded(
              child: Center(
                child: KidCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        perfect
                            ? Icons.auto_awesome
                            : Icons.emoji_events_outlined,
                        size: 48,
                        color: UserRole.child.accent,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Nice work!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('$_score / ${game.questions.length} correct'),
                      Text('Best score $best / ${game.questions.length}'),
                      Text(
                        _saving && _saved == null
                            ? 'Saving your score…'
                            : awarded == 0
                            ? 'Score saved. Points were already awarded for this game.'
                            : perfect
                            ? '+$awarded points for a perfect round'
                            : '+$awarded points added to your total',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: _saving ? 'Saving…' : 'Done',
                        expand: true,
                        compact: true,
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final QuizQuestion question = game.questions[_index];
    return AppPage(
      title: '',
      tint: UserRole.child.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTopBar(title: game.title),
          Text('Question ${_index + 1} of ${game.questions.length}'),
          LinearProgressIndicator(
            value: (_index + 1) / game.questions.length,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < question.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: KidCard(
                background: _picked == null
                    ? null
                    : i == question.correctIndex
                    ? AppColors.mint.withValues(alpha: 0.35)
                    : i == _picked
                    ? AppColors.blush.withValues(alpha: 0.45)
                    : null,
                onTap: _locked
                    ? null
                    : () {
                        setState(() {
                          _picked = i;
                          _locked = true;
                          if (i == question.correctIndex) _score += 1;
                        });
                      },
                child: Text(question.choices[i]),
              ),
            ),
          if (_picked != null)
            Text(
              _picked == question.correctIndex
                  ? 'That’s right!'
                  : 'Not quite — keep going.',
            ),
          const Spacer(),
          PrimaryButton(
            label: _index == game.questions.length - 1 ? 'See results' : 'Next',
            expand: true,
            onPressed: !_locked
                ? null
                : () {
                    if (_index == game.questions.length - 1) {
                      _finish();
                      return;
                    }
                    setState(() {
                      _index += 1;
                      _picked = null;
                      _locked = false;
                    });
                  },
          ),
        ],
      ),
    );
  }
}
