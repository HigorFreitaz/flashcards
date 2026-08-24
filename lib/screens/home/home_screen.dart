import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../state/app_state.dart';
import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';
import '../../utils/pt_br_date.dart';
import '../../widgets/buttons/lume_button.dart';
import 'widgets/progress_ring.dart';
import 'widgets/week_streak_row.dart';
import '../alerts/alerts_screen.dart';
import '../deck/deck_detail_screen.dart';
import '../study/study_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onGoToChallengeTab, required this.onGoToLibraryTab});

  final VoidCallback onGoToChallengeTab;
  final VoidCallback onGoToLibraryTab;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final dueToday = app.dueToday;
    final dailyGoalTarget = app.decks.isEmpty
        ? 1
        : app.decks.fold<int>(0, (sum, d) => sum + d.dailyGoal);
    final dailyPercent = dailyGoalTarget == 0 ? 0.0 : (1 - dueToday / dailyGoalTarget).clamp(0.0, 1.0).toDouble();
    final recentDecks = [...app.decks]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatLongDatePtBr(DateTime.now()),
                        style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w500, color: context.lume.inkMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${greetingForHour(DateTime.now().hour)}, ${app.currentUser!.firstName}',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: context.lume.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                _AlertsButton(
                  unread: app.unreadNotificationCount > 0,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DailyGoalCard(
              dueToday: dueToday,
              percent: dailyPercent,
              onStudy: dueToday == 0
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => StudyScreen(
                          queue: StudyQueueItem.fromDecks(app.decks),
                          sessionTitle: 'Revisão do dia',
                        ),
                      )),
            ),
            const SizedBox(height: 12),
            _StreakCard(app: app),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatTile(value: '${(app.weeklyAccuracy * 100).round()}%', label: 'precisão na semana')),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(value: '${app.minutesStudiedToday}', suffix: ' min', label: 'estudados hoje')),
              ],
            ),
            const SizedBox(height: 12),
            _ChallengeTeaser(onTap: onGoToChallengeTab),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continuar',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: context.lume.ink),
                ),
                TextButton(
                  onPressed: onGoToLibraryTab,
                  child: Text(
                    'Ver tudo',
                    style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: context.lume.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...recentDecks.take(3).map((deck) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ContinueDeckCard(
                    deck: deck,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeckDetailScreen(deckId: deck.id))),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _AlertsButton extends StatelessWidget {
  const _AlertsButton({required this.unread, required this.onTap});

  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.lume.background,
          border: Border.all(color: context.lume.outline),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 21, color: context.lume.ink),
            if (unread)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.lume.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.lume.background, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.dueToday, required this.percent, required this.onStudy});

  final int dueToday;
  final double percent;
  final VoidCallback? onStudy;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: const EdgeInsets.all(LumeSpacing.cardPadding),
      decoration: BoxDecoration(color: context.lume.primary, borderRadius: BorderRadius.circular(LumeRadii.card)),
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                percent: percent,
                size: 76,
                trackColor: context.lume.background.withValues(alpha: 0.25),
                progressColor: context.lume.background,
                child: Text(
                  '${(percent * 100).round()}%',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w700, color: context.lume.background),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meta de hoje',
                        style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w500, color: context.lume.background.withValues(alpha: 0.8))),
                    const SizedBox(height: 5),
                    Text('$dueToday cartões',
                        style: TextStyle(fontFamily: fontFamily, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1, color: context.lume.background)),
                    const SizedBox(height: 5),
                    Text('prontos para revisar',
                        style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: context.lume.background.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LumeButton(
            label: dueToday == 0 ? 'Tudo revisado' : 'Revisar agora',
            onPressed: onStudy,
            height: 50,
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final xpProgress = app.totalXp / (app.totalXp + app.xpToNextLevel);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.lume.background,
        border: Border.all(color: context.lume.outline),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sequência de ${app.streakDays} dias',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: context.lume.ink)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(10)),
                child: Text('Nível ${app.level}',
                    style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w700, color: context.lume.primary)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          WeekStreakRow(progress: app.weekProgress, today: 1),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${app.totalXp} XP', style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: context.lume.inkMuted)),
              Text('faltam ${app.xpToNextLevel} para o nível ${app.level + 1}',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: context.lume.inkMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: xpProgress),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: context.lume.surface,
                color: context.lume.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.suffix});

  final String value;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.lume.background,
        border: Border.all(color: context.lume.outline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontFamily: fontFamily, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: context.lume.ink),
              children: [
                TextSpan(text: value),
                if (suffix != null) TextSpan(text: suffix, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: context.lume.inkMuted)),
        ],
      ),
    );
  }
}

class _ChallengeTeaser extends StatelessWidget {
  const _ChallengeTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DESAFIO DA SEMANA',
                      style: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: context.lume.primary)),
                  const SizedBox(height: 6),
                  Text('11 de 15 perguntas respondidas',
                      style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, color: context.lume.ink)),
                  const SizedBox(height: 4),
                  Text('Termina em 2 dias · +250 XP', style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: context.lume.inkMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.lume.primary),
          ],
        ),
      ),
    );
  }
}

class _ContinueDeckCard extends StatelessWidget {
  const _ContinueDeckCard({required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final percent = deck.masteryPercent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.lume.background,
          border: Border.all(color: context.lume.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: context.lume.ink)),
                      const SizedBox(height: 4),
                      Text('${deck.totalCount} cartões',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: context.lume.inkMuted)),
                    ],
                  ),
                ),
                Text('${(percent * 100).round()}%',
                    style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w700, color: context.lume.primary)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: context.lume.surface,
                color: context.lume.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
