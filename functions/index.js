const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

exports.createChildAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to continue.");
  }

  const email = String(request.data?.email || "").trim();
  const password = String(request.data?.password || "");
  const name = String(request.data?.name || "").trim();
  if (!email || !password || !name) {
    throw new HttpsError("invalid-argument", "Missing child details.");
  }

  const db = getFirestore();
  const parentRef = db.collection("users").doc(request.auth.uid);
  const parentSnap = await parentRef.get();
  if (!parentSnap.exists || parentSnap.data().role !== "parent") {
    throw new HttpsError(
        "permission-denied",
        "Only a parent can add a child.",
    );
  }

  const familyId = parentSnap.data().familyId;
  if (!familyId) {
    throw new HttpsError("failed-precondition", "No family found.");
  }

  const familySnap = await db.collection("families").doc(familyId).get();
  if (!familySnap.exists || familySnap.data().parentId !== request.auth.uid) {
    throw new HttpsError(
        "permission-denied",
        "You do not own this family.",
    );
  }

  let userRecord;
  try {
    userRecord = await getAuth().createUser({
      email,
      password,
      displayName: name,
    });
  } catch (error) {
    if (error?.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "That email is already in use.");
    }
    throw new HttpsError("internal", "Unable to create that child account.");
  }

  const uid = userRecord.uid;
  const now = FieldValue.serverTimestamp();
  const profile = {
    uid,
    name,
    email,
    role: "child",
    familyId,
    locationSharingEnabled: false,
    dailyScreenLimitMinutes: 120,
    createdAt: now,
  };

  const batch = db.batch();
  batch.set(db.collection("users").doc(uid), profile);
  batch.set(
      db.collection("families").doc(familyId).collection("children").doc(uid),
      {
        uid,
        name,
        email,
        role: "child",
        familyId,
        createdAt: now,
      },
  );
  await batch.commit();

  return {uid, familyId};
});
