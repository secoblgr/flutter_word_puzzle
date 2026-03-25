const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// ---------------------------------------------------------------------------
// 1. Duel Invite → Push notification to receiver
// ---------------------------------------------------------------------------

exports.onDuelInviteCreated = onDocumentCreated(
  "duel_invites/{inviteId}",
  async (event) => {
    const invite = event.data.data();
    if (!invite) return;

    const toId = invite.toId;
    if (!toId) return;

    // Get receiver's FCM token.
    const userDoc = await db.collection("users").doc(toId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    // Get sender's name.
    const fromId = invite.fromId;
    let senderName = "Someone";
    if (fromId) {
      const fromDoc = await db.collection("users").doc(fromId).get();
      if (fromDoc.exists) {
        senderName = fromDoc.data().name || "Someone";
      }
    }

    // Send push notification.
    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Duel Invite! ⚔️",
          body: `${senderName} wants to duel with you!`,
        },
        data: {
          type: "duel_invite",
          inviteId: event.params.inviteId,
          fromId: fromId || "",
          fromName: senderName,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "word_puzzle_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });
      console.log(`Duel invite notification sent to ${toId}`);
    } catch (error) {
      console.error("Failed to send duel invite notification:", error);
    }
  }
);

// ---------------------------------------------------------------------------
// 2. Friend Request → Push notification to receiver
// ---------------------------------------------------------------------------

exports.onFriendRequestCreated = onDocumentCreated(
  "friend_requests/{requestId}",
  async (event) => {
    const request = event.data.data();
    if (!request) return;

    const toId = request.toId;
    if (!toId) return;

    // Get receiver's FCM token.
    const userDoc = await db.collection("users").doc(toId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const senderName = request.fromName || "Someone";

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Friend Request! 👥",
          body: `${senderName} wants to be your friend!`,
        },
        data: {
          type: "friend_request",
          requestId: event.params.requestId,
          fromId: request.fromId || "",
          fromName: senderName,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "word_puzzle_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });
      console.log(`Friend request notification sent to ${toId}`);
    } catch (error) {
      console.error("Failed to send friend request notification:", error);
    }
  }
);

// ---------------------------------------------------------------------------
// 3. Duel Invite Accepted → Notify sender
// ---------------------------------------------------------------------------

exports.onDuelInviteAccepted = onDocumentUpdated(
  "duel_invites/{inviteId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;

    // Only trigger when status changes to 'accepted'.
    if (before.status === "accepted" || after.status !== "accepted") return;

    const fromId = after.fromId;
    if (!fromId) return;

    // Get sender's FCM token.
    const userDoc = await db.collection("users").doc(fromId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    // Get acceptor's name.
    let acceptorName = "Your friend";
    if (after.toId) {
      const toDoc = await db.collection("users").doc(after.toId).get();
      if (toDoc.exists) {
        acceptorName = toDoc.data().name || "Your friend";
      }
    }

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Duel Accepted! ⚔️",
          body: `${acceptorName} accepted your duel! Get ready!`,
        },
        data: {
          type: "duel_accepted",
          duelId: after.duelId || "",
          inviteId: event.params.inviteId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "word_puzzle_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });
      console.log(`Duel accepted notification sent to ${fromId}`);
    } catch (error) {
      console.error("Failed to send duel accepted notification:", error);
    }
  }
);

// ---------------------------------------------------------------------------
// 4. Duel Invite Rejected → Notify sender
// ---------------------------------------------------------------------------

exports.onDuelInviteRejected = onDocumentUpdated(
  "duel_invites/{inviteId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;

    // Only trigger when status changes to 'rejected'.
    if (before.status === "rejected" || after.status !== "rejected") return;

    const fromId = after.fromId;
    if (!fromId) return;

    const userDoc = await db.collection("users").doc(fromId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    let rejectorName = "Your friend";
    if (after.toId) {
      const toDoc = await db.collection("users").doc(after.toId).get();
      if (toDoc.exists) {
        rejectorName = toDoc.data().name || "Your friend";
      }
    }

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Duel Declined 😔",
          body: `${rejectorName} declined your duel invite.`,
        },
        data: {
          type: "duel_rejected",
          inviteId: event.params.inviteId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "word_puzzle_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });
      console.log(`Duel rejected notification sent to ${fromId}`);
    } catch (error) {
      console.error("Failed to send duel rejected notification:", error);
    }
  }
);
