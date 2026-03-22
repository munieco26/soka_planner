const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Convierte un campo Firestore Timestamp (o _seconds) a Date.
 */
function toDate(field) {
  if (field && typeof field.toDate === "function") {
    return field.toDate();
  }
  if (field && field._seconds) {
    return new Date(field._seconds * 1000);
  }
  return null;
}

/**
 * Envia push FCM y marca notificationSent = true.
 */
async function sendPush(docRef, deviceId, eventTitle) {
  await getMessaging().send({
    token: deviceId,
    notification: {
      title: "Recordatorio",
      body: `Tenés: ${eventTitle}`,
    },
    data: { type: "reminder" },
  });
  await docRef.update({ notificationSent: true });
}

// -------------------------------------------------------
// A) Trigger on reminder create/update — immediate sends
// -------------------------------------------------------
exports.sendReminderPush = onDocumentWritten(
  "reminders/{reminderId}",
  async (event) => {
    const after = event.data?.after;
    if (!after) {
      console.log("Documento borrado, no hacer nada");
      return;
    }

    const data = after.data();
    if (!data) {
      console.log("Documento vacio o sin datos");
      return;
    }

    const {
      reminderType,
      reminderTime,
      eventTitle,
      deviceId,
      notificationSent,
      isActive,
    } = data;

    if (reminderType !== "push" || !isActive || notificationSent) {
      return;
    }

    if (!deviceId || typeof deviceId !== "string") {
      console.log("deviceId invalido:", deviceId);
      return;
    }

    const reminderDate = toDate(reminderTime);
    if (!reminderDate) {
      console.log("reminderTime invalido:", reminderTime);
      return;
    }

    const now = new Date();
    if (reminderDate <= now) {
      console.log("Enviando push inmediato (recordatorio atrasado)");
      await sendPush(after.ref, deviceId, eventTitle);
      console.log("Push enviado inmediato");
    }
    // Si reminderDate es futuro, el scheduler se encarga.
  }
);

// -------------------------------------------------------
// B) Scheduled — every 1 minute, catch future reminders
// -------------------------------------------------------
exports.checkPendingReminders = onSchedule("every 1 minutes", async () => {
  const db = getFirestore();
  const now = new Date();

  const snapshot = await db
    .collection("reminders")
    .where("reminderType", "==", "push")
    .where("isActive", "==", true)
    .where("notificationSent", "==", false)
    .get();

  if (snapshot.empty) {
    console.log("No hay reminders pendientes");
    return;
  }

  const promises = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const reminderDate = toDate(data.reminderTime);

    if (!reminderDate || reminderDate > now) {
      continue;
    }

    if (!data.deviceId || typeof data.deviceId !== "string") {
      console.log("deviceId invalido en doc:", doc.id);
      continue;
    }

    console.log("Enviando push para reminder:", doc.id);
    promises.push(
      sendPush(doc.ref, data.deviceId, data.eventTitle).catch((err) => {
        console.error("Error enviando push para", doc.id, err);
      })
    );
  }

  await Promise.all(promises);
  console.log("checkPendingReminders completado,", promises.length, "enviados");
});
