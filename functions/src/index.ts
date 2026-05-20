import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
  Timestamp,
  type DocumentData,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

initializeApp();

const db = getFirestore();
const defaultScore = 100;
const minScore = 0;
const maxScore = 100;

export const backfillOverdueCreditScores = onSchedule(
  {
    schedule: "every day 00:15",
    timeZone: "Etc/UTC",
  },
  async () => {
    const snapshot = await db
      .collection("debts")
      .where("status", "==", "active")
      .get();
    const now = new Date();

    for (const doc of snapshot.docs) {
      await applyOverdueEventsForDebt(doc.id, doc.data(), now);
    }
  },
);

export const handleDebtSettlementCreditScore = onDocumentWritten(
  "debts/{debtId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const debtId = event.params.debtId;

    if (!after) return;
    if (after.status !== "settled") return;
    if (before?.status === "settled") return;

    const hasAcceptedSettlement = await hasAcceptedSettlementRequest(debtId);
    if (!hasAcceptedSettlement) {
      logger.warn("Ignoring settlement score update without accepted request", {
        debtId,
      });
      return;
    }

    const settledAt = readDate(after.settled_at) ?? new Date();
    await applyOverdueEventsForDebt(debtId, after, settledAt);

    const deadline = readDate(after.deadline);
    if (deadline == null) return;
    if (settledAt.getTime() >= deadlineDueAtUtc(deadline).getTime()) return;

    await applyCreditScoreEvent({
      eventId: `${debtId}_on_time_settlement`,
      userId: borrowerId(after),
      debtId,
      eventType: "on_time_settlement",
      points: 3,
      eventDate: settledAt,
    });
  },
);

async function hasAcceptedSettlementRequest(debtId: string): Promise<boolean> {
  const snapshot = await db
    .collection("inbox_items")
    .where("payload.debt_ids", "array-contains", debtId)
    .get();

  return snapshot.docs.some((doc) => {
    const data = doc.data();
    return (
      data.type === "settlement_request" &&
      data.status === "accepted"
    );
  });
}

async function applyOverdueEventsForDebt(
  debtId: string,
  debtData: DocumentData,
  now: Date,
): Promise<void> {
  if (debtData.status !== "active" && debtData.status !== "settled") return;

  const deadline = readDate(debtData.deadline);
  if (deadline == null) return;

  const dueAt = deadlineDueAtUtc(deadline);
  const current = new Date(now.toISOString());
  if (current.getTime() < dueAt.getTime()) return;

  const borrower = borrowerId(debtData);
  const missedDeadlineDate = new Date(
    Date.UTC(deadline.getUTCFullYear(), deadline.getUTCMonth(), deadline.getUTCDate()),
  );
  await applyCreditScoreEvent({
    eventId: `${debtId}_missed_deadline`,
    userId: borrower,
    debtId,
    eventType: "missed_deadline",
    points: -5,
    eventDate: missedDeadlineDate,
  });

  const fullOverdueDays = Math.floor(
    (current.getTime() - dueAt.getTime()) / (24 * 60 * 60 * 1000),
  );
  for (let dayOffset = 1; dayOffset <= fullOverdueDays; dayOffset += 1) {
    const eventDate = new Date(
      Date.UTC(
        deadline.getUTCFullYear(),
        deadline.getUTCMonth(),
        deadline.getUTCDate() + dayOffset,
      ),
    );
    await applyCreditScoreEvent({
      eventId: `${debtId}_overdue_day_${dateKey(eventDate)}`,
      userId: borrower,
      debtId,
      eventType: "overdue_day",
      points: -1,
      eventDate,
    });
  }
}

async function applyCreditScoreEvent({
  eventId,
  userId,
  debtId,
  eventType,
  points,
  eventDate,
}: {
  eventId: string;
  userId: string;
  debtId: string;
  eventType: string;
  points: number;
  eventDate: Date;
}): Promise<void> {
  const eventRef = db.collection("credit_score_events").doc(eventId);
  const userRef = db.collection("users").doc(userId);

  await db.runTransaction(async (tx) => {
    const eventSnapshot = await tx.get(eventRef);
    if (eventSnapshot.exists) return;

    const userSnapshot = await tx.get(userRef);
    const currentScoreRaw = userSnapshot.data()?.credit_score;
    const currentScore =
      typeof currentScoreRaw === "number" ? currentScoreRaw : defaultScore;
    const nextScore = clamp(currentScore + points);

    tx.set(eventRef, {
      user_id: userId,
      debt_id: debtId,
      event_type: eventType,
      points,
      event_date: Timestamp.fromDate(dateOnlyUtc(eventDate)),
      created_at: FieldValue.serverTimestamp(),
    });
    tx.set(userRef, {credit_score: nextScore}, {merge: true});
  });
}

function borrowerId(debtData: DocumentData): string {
  const ownerId = asString(debtData.owner_id);
  const counterpartId = asString(debtData.counterpart_id);
  const direction = asString(debtData.direction, "borrow");
  return direction === "lend" ? counterpartId : ownerId;
}

function deadlineDueAtUtc(deadline: Date): Date {
  return new Date(
    Date.UTC(
      deadline.getUTCFullYear(),
      deadline.getUTCMonth(),
      deadline.getUTCDate() + 1,
    ),
  );
}

function dateOnlyUtc(date: Date): Date {
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
}

function dateKey(date: Date): string {
  return dateOnlyUtc(date).toISOString().split("T")[0];
}

function clamp(score: number): number {
  return Math.max(minScore, Math.min(maxScore, score));
}

function readDate(value: unknown): Date | null {
  if (value instanceof Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" ? value : fallback;
}
