/* eslint-disable no-console */
const fs = require("node:fs");
const path = require("node:path");
const {initializeApp} = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

const projectId = resolveProjectId();

initializeApp({projectId});

const db = getFirestore();
const usernamePattern = /^[a-z0-9_]{3,20}$/;

main().catch((error) => {
  if (String(error?.message || "").includes("Could not load the default credentials")) {
    console.error(
        [
          "Missing Google application credentials for the migration script.",
          "Run one of these before retrying:",
          "1. gcloud auth application-default login",
          "2. Set GOOGLE_APPLICATION_CREDENTIALS to a Firebase service-account JSON file",
          `Project id in use: ${projectId}`,
        ].join("\n"),
    );
  } else {
    console.error(error);
  }
  process.exitCode = 1;
});

async function main() {
  const usersSnapshot = await db.collection("users").get();
  let migrated = 0;

  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    const emailName = typeof data.email === "string" ?
      data.email.split("@")[0] :
      "";
    const displayName = firstNonEmpty([
      data.display_name,
      emailName,
      "Profile",
    ]);
    const desiredUsername = firstNonEmpty([
      data.username,
      emailName,
      doc.id.slice(0, 8),
    ]);
    const username = await reserveUsername(desiredUsername, doc.id);

    const batch = db.batch();
    batch.set(db.collection("user_profiles").doc(doc.id), {
      display_name: displayName,
      username,
      username_lower: username,
      created_at: data.created_at ?? FieldValue.serverTimestamp(),
    }, {merge: true});
    batch.set(db.collection("username_claims").doc(username), {
      owner_uid: doc.id,
      username_lower: username,
      created_at: FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();
    migrated += 1;
  }

  console.log(`Migrated ${migrated} user profiles.`);
}

async function reserveUsername(value, uid) {
  let base = suggestUsername(value, uid.slice(0, 8));
  let candidate = base;
  let suffix = 0;

  while (true) {
    const claimSnapshot = await db.collection("username_claims").doc(candidate).get();
    if (!claimSnapshot.exists || claimSnapshot.data().owner_uid === uid) {
      return candidate;
    }

    suffix += 1;
    const suffixText = `_${suffix}`;
    candidate = `${base.slice(0, 20 - suffixText.length)}${suffixText}`;
  }
}

function suggestUsername(value, fallback) {
  const normalized = String(value || "").trim().toLowerCase();
  const sanitized = normalized.replace(/[^a-z0-9_]/g, "_");
  const collapsed = sanitized.replace(/_+/g, "_");
  const trimmed = collapsed.replace(/^_+|_+$/g, "");
  const candidate = trimmed.slice(0, 20);
  if (usernamePattern.test(candidate)) {
    return candidate;
  }

  const fallbackCandidate = String(fallback || "profile")
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9_]/g, "_")
      .slice(0, 20);
  if (usernamePattern.test(fallbackCandidate)) {
    return fallbackCandidate;
  }

  return "profile_user";
}

function firstNonEmpty(values) {
  for (const value of values) {
    const trimmed = typeof value === "string" ? value.trim() : "";
    if (trimmed) {
      return trimmed;
    }
  }
  return "";
}

function resolveProjectId() {
  const envProjectId = process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID;
  if (envProjectId) {
    return envProjectId;
  }

  const firebaseJsonPath = path.resolve(__dirname, "..", "..", "firebase.json");
  const firebaseJson = JSON.parse(fs.readFileSync(firebaseJsonPath, "utf8"));
  const projectFromFirebaseJson =
    firebaseJson?.flutter?.platforms?.dart?.["lib/firebase_options.dart"]?.projectId ||
    firebaseJson?.flutter?.platforms?.android?.default?.projectId;

  if (projectFromFirebaseJson) {
    return projectFromFirebaseJson;
  }

  throw new Error(
      "Unable to resolve Firebase project id. Set GOOGLE_CLOUD_PROJECT or add projectId to firebase.json.",
  );
}
