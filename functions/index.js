const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

/** @param {string} uid */
async function getFcmTokensForUser(uid) {
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .get();
  return snap.docs.map((d) => d.get("token")).filter(Boolean);
}

/**
 * @param {string} token
 * @param {string} title
 * @param {string} body
 * @param {Record<string, string>} data
 */
async function sendToToken(token, title, body, data) {
  await getMessaging().send({
    token,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v ?? "")])
    ),
  });
}

/** @param {string} userId */
async function sendToUser(userId, title, body, data) {
  const tokens = await getFcmTokensForUser(userId);
  await Promise.all(
    tokens.map((t) =>
      sendToToken(t, title, body, data).catch((err) => {
        console.error("FCM fail", userId, err.message);
      })
    )
  );
}

/**
 * @param {string} userId
 * @param {string} title
 * @param {string} body
 * @param {string} type
 * @param {Record<string, unknown>} extra
 */
async function saveInboxNotification(userId, title, body, type, extra = {}) {
  await db.collection("notifications").add({
    userId,
    title,
    body,
    type,
    receivedAt: FieldValue.serverTimestamp(),
    isRead: false,
    ...extra,
  });
}

// --- Nuevo miembro en calendario ---
exports.onCalendarMemberJoined = onDocumentCreated(
  {
    document: "calendars/{calendarId}/members/{memberUid}",
    region: "us-central1",
  },
  async (event) => {
    const { calendarId, memberUid } = event.params;
    const calSnap = await db.collection("calendars").doc(calendarId).get();
    if (!calSnap.exists) return;

    const cal = calSnap.data();
    const memberUids = cal.memberUids || [];
    const calName = cal.name || "Calendario";
    const memberData = event.data?.data() || {};
    const name =
      memberData.displayName || memberData.email || "Alguien";

    const title = `${name} se unió`;
    const body = `${name} se unió a «${calName}»`;

    for (const uid of memberUids) {
      if (uid === memberUid) continue;
      await saveInboxNotification(uid, title, body, "member_joined", {
        calendarId,
      });
      await sendToUser(uid, title, body, {
        type: "member_joined",
        calendarId,
      });
    }
  }
);

// --- Crear / actualizar / eliminar evento ---
exports.onCalendarEventChange = onDocumentWritten(
  {
    document: "calendars/{calendarId}/events/{eventId}",
    region: "us-central1",
  },
  async (event) => {
    const { calendarId, eventId } = event.params;
    const before = event.data.before;
    const after = event.data.after;

    const calSnap = await db.collection("calendars").doc(calendarId).get();
    if (!calSnap.exists) return;

    const cal = calSnap.data();
    const memberUids = cal.memberUids || [];
    const calName = cal.name || "";

    let title;
    let body;
    let type;
    /** @type {string | undefined} */
    let skipUid;

    if (!before.exists && after.exists) {
      const d = after.data();
      title = "Nuevo evento";
      body = `«${d.title || "Evento"}» en ${calName}`;
      type = "event_created";
      skipUid = d.createdBy;
    } else if (before.exists && after.exists) {
      const d = after.data();
      title = "Evento actualizado";
      body = `«${d.title || "Evento"}» fue modificado en ${calName}`;
      type = "event_updated";
      skipUid = undefined;
    } else if (before.exists && !after.exists) {
      const d = before.data();
      title = "Evento eliminado";
      body = `«${d.title || "Un evento"}» fue eliminado de ${calName}`;
      type = "event_deleted";
      skipUid = undefined;
    } else {
      return;
    }

    const dataPayload = {
      type,
      calendarId,
      eventId,
    };

    for (const uid of memberUids) {
      if (skipUid && uid === skipUid) continue;
      await saveInboxNotification(uid, title, body, type, {
        calendarId,
        eventId,
      });
      await sendToUser(uid, title, body, dataPayload);
    }
  }
);

// --- Recordatorios: ejecutar cada 2 minutos ---
exports.processDueReminders = onSchedule(
  {
    schedule: "every 2 minutes",
    region: "us-central1",
    timeZone: "America/Argentina/Buenos_Aires",
  },
  async () => {
    const now = Timestamp.now();
    const snap = await db
      .collection("reminders")
      .where("reminderType", "==", "push")
      .where("isActive", "==", true)
      .where("notificationSent", "==", false)
      .where("reminderTime", "<=", now)
      .limit(100)
      .get();

    if (snap.empty) return;

    for (const doc of snap.docs) {
      const data = doc.data();
      const token = data.deviceId;
      if (!token || typeof token !== "string") continue;

      const eventTitle = data.eventTitle || "Evento";

      try {
        await getMessaging().send({
          token,
          notification: {
            title: "Recordatorio",
            body: `Tenés: ${eventTitle}`,
          },
          data: {
            type: "reminder",
            eventId: String(data.eventId || ""),
            calendarId: String(data.calendarId || ""),
          },
        });
        await doc.ref.update({ notificationSent: true });
      } catch (e) {
        console.error("Reminder FCM error", doc.id, e.message);
      }
    }
  }
);
