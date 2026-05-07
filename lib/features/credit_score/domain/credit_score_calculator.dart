class CreditScoreCalculator {
  const CreditScoreCalculator._();

  static const defaultScore = 100;
  static const minScore = 0;
  static const maxScore = 100;
  static const missedDeadlinePenalty = -5;
  static const overdueDayPenalty = -1;
  static const onTimeSettlementReward = 3;

  static int clamp(int score) {
    if (score < minScore) return minScore;
    if (score > maxScore) return maxScore;
    return score;
  }

  static DateTime deadlineDueAtUtc(DateTime deadline) {
    return DateTime.utc(deadline.year, deadline.month, deadline.day + 1);
  }

  static bool isOverdue({required DateTime deadline, required DateTime now}) {
    return !now.toUtc().isBefore(deadlineDueAtUtc(deadline));
  }

  static int fullUnpaidDaysAfterDeadline({
    required DateTime deadline,
    required DateTime now,
  }) {
    final dueAt = deadlineDueAtUtc(deadline);
    final nowUtc = now.toUtc();
    if (nowUtc.isBefore(dueAt)) return 0;
    return nowUtc.difference(dueAt).inHours ~/ 24;
  }

  static int overduePenalty({
    required DateTime deadline,
    required DateTime now,
  }) {
    if (!isOverdue(deadline: deadline, now: now)) return 0;
    return missedDeadlinePenalty +
        fullUnpaidDaysAfterDeadline(deadline: deadline, now: now) *
            overdueDayPenalty;
  }

  static bool isOnTimeSettlement({
    required DateTime deadline,
    required DateTime settledAt,
  }) {
    return settledAt.toUtc().isBefore(deadlineDueAtUtc(deadline));
  }

  static int applyDelta(int currentScore, int delta) {
    return clamp(currentScore + delta);
  }
}
