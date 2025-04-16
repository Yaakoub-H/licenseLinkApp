const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { StreamChat } = require("stream-chat");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Initialize Stream Chat client with your Stream API credentials
const serverClient = StreamChat.getInstance(
  functions.config().stream.key,
  functions.config().stream.secret
);

/**
 * Callable function to create a Stream user and return an auth token.
 * This is intended to be called from your client app.
 */
exports.createStreamUserAndGetToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "This function must be called while authenticated."
    );
  }

  try {
    // Create the Stream user
    await serverClient.upsertUser({
      id: context.auth.uid,
      name: context.auth.token.name || "Anonymous",
      email: context.auth.token.email,
      image: context.auth.token.picture || null,
    });

    // Return the generated token
    const token = serverClient.createToken(context.auth.uid);
    return { token };
  } catch (err) {
    console.error(`Stream user creation failed: ${err.message}`);
    throw new functions.https.HttpsError("aborted", "Failed to create Stream user.");
  }
});
