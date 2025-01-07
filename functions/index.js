const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendLeaveRequestNotification = functions.firestore
    .document('leaveRequests/{requestId}')
    .onCreate((snap, context) => {
        const newValue = snap.data();
        const payload = {
            notification: {
                title: 'New Leave Request',
                body: `${newValue.name} has requested leave from ${newValue.fromDate} to ${newValue.toDate}.`,
                sound: 'default',
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                screen: 'LeaveRequestsPage.dart' // Custom data to indicate which screen to open
            },
        };

        return admin.messaging().sendToTopic('adminNotifications', payload)
            .then(response => {
                console.log('Successfully sent message:', response);
            })
            .catch(error => {
                console.log('Error sending message:', error);
            });
    });

// Function to send notification for issue submissions
exports.sendIssueNotification = functions.firestore
.document('user_issues/{issueId}')
.onCreate((snap, context) => {
    const issue = snap.data();
    const payload = {
        notification: {
            title: 'New Issue Submitted',
            body: `A new issue has been submitted by ${issue.username}: ${issue.title}`,
            sound: 'default',
        },
        data: {
            screen: 'IssuesPage'
        }
    };

    return admin.messaging().sendToTopic('admin_notifications', payload)
        .then(response => {
            console.log('Successfully sent issue notification:', response);
        })
        .catch(error => {
            console.log('Error sending issue notification:', error);
        });
});

// Function to send check-in reminder at 8:30 AM
exports.sendCheckInReminder = functions.pubsub.schedule('30 8 * * 1-5')
    .timeZone('Asia/Kolkata') // Adjust the time zone as needed
    .onRun(async (context) => {
        const payload = {
            notification: {
                title: 'Check-in Reminder',
                body: 'Please check in now.',
            },
        };

        const tokens = await getDeviceTokens();
        if (tokens.length > 0) {
            await admin.messaging().sendToDevice(tokens, payload);
            console.log('Check-in notifications sent successfully');
        }
    });

// Function to send check-out reminder at 4:00 PM
exports.sendCheckOutReminder = functions.pubsub.schedule('0 16 * * 1-5')
    .timeZone('Asia/Kolkata') // Adjust the time zone as needed
    .onRun(async (context) => {
        const payload = {
            notification: {
                title: 'Check-out Reminder',
                body: 'Please check out now.',
            },
        };

        const tokens = await getDeviceTokens();
        if (tokens.length > 0) {
            await admin.messaging().sendToDevice(tokens, payload);
            console.log('Check-out notifications sent successfully');
        }
    });

async function getDeviceTokens() {
    const tokens = [];
    const usersSnapshot = await admin.firestore().collection('users').get();
    usersSnapshot.forEach(userDoc => {
        const token = userDoc.data().fcmToken;
        if (token) {
            tokens.push(token);
        }
    });
    return tokens;
}
