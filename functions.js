const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendReminderPush = onDocumentWritten(
  "reminders/{reminderId}",
  async (event) => {

    const after = event.data?.after;
    if (!after) {
      console.log("🟡 Documento borrado, no hacer nada");
      return;
    }

    const data = after.data();
    if (!data) {
      console.log("🟡 Documento vacío o sin datos, no hacer nada");
      return;
    }

    console.log("📌 Reminder detectado:", data);

    const {
      reminderType,
      reminderTime,
      eventTitle,
      deviceId,
      notificationSent,
      isActive,
      eventStart,
    } = data;

    // Validaciones básicas
    if (reminderType !== "push") {
      console.log("🔕 No es reminder push, ignorando…");
      return;
    }

    if (!isActive) {
      console.log("⛔ Reminder inactivo, no se envía.");
      return;
    }

    if (notificationSent) {
      console.log("⛔ Ya fue enviado, no repetir.");
      return;
    }

    if (!deviceId || typeof deviceId !== "string") {
      console.log("❌ deviceId inválido:", deviceId);
      return;
    }

    // ---------------------------------------------
    // FIX IMPORTANTE: convertir reminderTime a Date
    // ---------------------------------------------
    let reminderDate;
    try {
      if (reminderTime && typeof reminderTime.toDate === "function") {
        // Timestamp real
        reminderDate = reminderTime.toDate();
      } else if (reminderTime?._seconds) {
        // Evento desde Eventarc
        reminderDate = new Date(reminderTime._seconds * 1000);
      } else {
        throw new Error("Valor inválido para reminderTime");
      }
    } catch (err) {
      console.log("❌ reminderTime inválido:", reminderTime, err);
      return;
    }

    // ---------------------------------------------
    // También convertimos eventStart si hace falta
    // ---------------------------------------------
    let eventStartDate;
    try {
      if (eventStart && typeof eventStart.toDate === "function") {
        eventStartDate = eventStart.toDate();
      } else if (eventStart?._seconds) {
        eventStartDate = new Date(eventStart._seconds * 1000);
      } else {
        eventStartDate = reminderDate; // fallback
      }
    } catch (err) {
      eventStartDate = reminderDate;
    }

    const now = new Date();
    const msUntilReminder = reminderDate - now;

    // ---------------------------------------------
    // Caso 1: reminder atrasado → enviar YA
    // ---------------------------------------------
    if (msUntilReminder <= 0) {
      console.log("⚡ Enviando push inmediato (recordatorio atrasado)");

      await getMessaging().send({
        token: deviceId,
        notification: {
          title: "Recordatorio",
          body: `Tenés: ${eventTitle}`,
        },
        data: { type: "reminder" },
      });

      await after.ref.update({ notificationSent: true });
      console.log("✅ Push enviado inmediato");
      return;
    }

    // ---------------------------------------------
    // Caso 2: reminder futuro → programar con setTimeout
    // ---------------------------------------------
    console.log("⏱ Programando push en:", msUntilReminder, "ms");

    setTimeout(async () => {
      console.log("⏰ Ejecutando push programado…");

      try {
        await getMessaging().send({
          token: deviceId,
          notification: {
            title: "Recordatorio",
            body: `Tenés: ${eventTitle}`,
          },
          data: { type: "reminder" },
        });

        await after.ref.update({ notificationSent: true });

        console.log("✅ Push programado enviado");
      } catch (err) {
        console.error("❌ Error enviando push programado:", err);
      }
    }, msUntilReminder);
  }
);
