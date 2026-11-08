const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const AfricasTalking = require("africastalking")({
  apiKey: functions.config().at.key,
  username: functions.config().at.username, // "sandbox" for now
});
const sms = AfricasTalking.SMS;

const OFFLINE_THRESHOLD_SECONDS = 35; // matches NetworkViewModel's own threshold

const OFFLINE_MESSAGES = {
  en: (deviceId, lastSeenStr) =>
    `Smart Dryer ${deviceId} has gone OFFLINE. Last seen at ${lastSeenStr}.`,
  lg: (deviceId, lastSeenStr) =>
    `Ekikaza ${deviceId} kivudde ku mutimbagano. Kyalabikira ${lastSeenStr}.`,
  sw: (deviceId, lastSeenStr) =>
    `Kikaushio ${deviceId} kimekatika mtandaoni. Kilionekana mara ya mwisho ${lastSeenStr}.`,
};

function normalizeLanguage(language) {
  const languageCode = String(language || "en").trim().toLowerCase();
  return OFFLINE_MESSAGES[languageCode] ? languageCode : "en";
}

function buildOfflineMessage(language, deviceId, lastSeenStr) {
  return OFFLINE_MESSAGES[normalizeLanguage(language)](
    deviceId,
    lastSeenStr
  );
}

exports.checkDryerOffline = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const db = admin.database();
    const snapshot = await db.ref("Devices/SmartDryer").once("value");
    const devices = snapshot.val();

    if (!devices) return null;

    const now = Date.now();
    const tasks = Object.entries(devices).map(async ([deviceId, data]) => {
      const lastSeenStr = data?.network?.lastSeen;
      const alertAlreadySent = data?.network?.smsAlertSent === true;
      const phone = data?.info?.phone;
      const language = data?.info?.language;

      if (!lastSeenStr) return; // device has never reported in, skip

      const lastSeen = new Date(lastSeenStr).getTime();
      const secondsSinceLastSeen = (now - lastSeen) / 1000;
      const isOffline = secondsSinceLastSeen > OFFLINE_THRESHOLD_SECONDS;

      const deviceRef = db.ref(`Devices/SmartDryer/${deviceId}/network`);

      if (isOffline && !alertAlreadySent) {
        // Device just went offline — fire the alert once
        if (phone && phone !== "null") {
          try {
            await sms.send({
              to: [phone],
              message: buildOfflineMessage(language, deviceId, lastSeenStr),
              from: "AFRICASTKNG",
            });
            functions.logger.log(`SMS sent for offline device ${deviceId}`);
          } catch (err) {
            functions.logger.error(`SMS failed for ${deviceId}:`, err);
          }
        }
        await deviceRef.update({ smsAlertSent: true });
      } else if (!isOffline && alertAlreadySent) {
        // Device came back — reset so next outage can alert again
        await deviceRef.update({ smsAlertSent: false });
      }
    });

    await Promise.all(tasks);
    return null;
  });