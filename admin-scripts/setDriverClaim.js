const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = process.env.DRIVER_UID;

admin.auth().setCustomUserClaims(uid, { driver: true })
  .then(() => {
    console.log(`Custom claims set for user: ${uid}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error setting custom claims:', error);
    process.exit(1);
  });