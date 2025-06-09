const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// HTTP Function to check and sync every 10 minutes
exports.backupUsers = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    const usersSnapshot = await db.collection("users").get();

    if (usersSnapshot.empty) {
      console.log("No users found for backup.");
      res.status(200).send({
        "message": "No users found for backup.",
        "pendingSyncCount": 0,
      });
      return;
    }

    const batch = db.batch();
    let pendingSyncCount = 0;
    const now = new Date();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const lastBackup = userData.lastBackup ?
        userData.lastBackup.toDate() : null;

      // Check if not synced or 10 minutes have passed since last sync
      if (!lastBackup || (now - lastBackup) >= 10 * 60 * 1000) {
        pendingSyncCount += 1;
        console.log(`Backing up data for user: ${userId}`);
        const userRef = db.collection("users").doc(userId);
        batch.set(userRef, {
          "lastBackup": admin.firestore.FieldValue.serverTimestamp(),
        }, {"merge": true});
      }
    }

    if (pendingSyncCount > 0) {
      await batch.commit();
      console.log(`Backup completed for ${pendingSyncCount} users.`);
      res.status(200).send({
        "message": `Backup completed for ${pendingSyncCount} users.`,
        "pendingSyncCount": pendingSyncCount,
      });
    } else {
      console.log("No users need backup at this time.");
      res.status(200).send({
        "message": "No users need backup at this time.",
        "pendingSyncCount": 0,
      });
    }
  } catch (error) {
    console.error("Error during backup:", error);
    res.status(500).send({
      "message": "Backup failed: " + error.message,
      "pendingSyncCount": 0,
    });
  }
});

// HTTP Function to force sync immediately
exports.forceBackup = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    const usersSnapshot = await db.collection("users").get();

    if (usersSnapshot.empty) {
      console.log("No users found for backup.");
      res.status(200).send({
        "message": "No users found for backup.",
        "pendingSyncCount": 0,
      });
      return;
    }

    const batch = db.batch();
    let pendingSyncCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      console.log(`Force backing up data for user: ${userId}`);
      const userRef = db.collection("users").doc(userId);
      batch.set(userRef, {
        "lastBackup": admin.firestore.FieldValue.serverTimestamp(),
      }, {"merge": true});
      pendingSyncCount += 1;
    }

    await batch.commit();
    console.log(`Force backup completed for ${pendingSyncCount} users.`);
    res.status(200).send({
      "message": `Force backup completed for ${pendingSyncCount} users.`,
      "pendingSyncCount": pendingSyncCount,
    });
  } catch (error) {
    console.error("Error during force backup:", error);
    res.status(500).send({
      "message": "Force backup failed: " + error.message,
      "pendingSyncCount": 0,
    });
  }
});
