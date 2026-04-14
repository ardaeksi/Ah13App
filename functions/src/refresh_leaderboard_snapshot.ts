import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";

admin.initializeApp();

// Writes a compact top-7 leaderboard snapshot to Firestore.
// Schedule: every 72 hours (3 days)
export const refresh_leaderboard_snapshot = onSchedule(
  {
    schedule: "every 72 hours",
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    const db = admin.firestore();
    const nowIso = new Date().toISOString();

    logger.info("Refreshing leaderboard snapshot", { nowIso });

    const snap = await db
      .collection("users")
      .orderBy("totalPoints", "desc")
      .limit(7)
      .get();

    const entries = snap.docs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      const displayName = (data["name"] ?? data["displayName"] ?? "Player").toString();
      const pointsRaw = (data["totalPoints"] ?? 0) as unknown;
      const totalPoints = typeof pointsRaw === "number" ? Math.floor(pointsRaw) : parseInt(String(pointsRaw || 0), 10) || 0;
      return { uid: d.id, displayName, totalPoints };
    });

    logger.info("Top entries computed", { count: entries.length });

    await db.doc("leaderboards/global_top7").set(
      {
        entries,
        generatedAt: nowIso,
        updated_at: nowIso,
      },
      { merge: true }
    );

    logger.info("Leaderboard snapshot written", { docPath: "leaderboards/global_top7" });
  }
);
