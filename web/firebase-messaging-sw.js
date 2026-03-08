// Import Firebase app and messaging
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// Initialize Firebase in the service worker
firebase.initializeApp({
    apiKey: "AIzaSyDFF_wtP_oYpbY9CIkvFphNG6uqTOb2mU",
    authDomain: "actmgr-9b618.firebaseapp.com",
    projectId: "actmgr-9b618",
    storageBucket: "actmgr-9b618.firebasestorage.app",
    messagingSenderId: "2918996686",
    appId: "1:2918996686:web:b721fcd574a9c548054e9f"
});

// Get messaging instance
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message:', payload);

    // Customize notification appearance
    const notificationTitle = payload.notification?.title || 'New Notification';
    const notificationOptions = {
        body: payload.notification?.body || 'You have a new message',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: 'notification-tag',
        data: payload.data
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', function (event) {
    console.log('[firebase-messaging-sw.js] Notification click:', event);

    event.notification.close();

    // Handle click action - focus the window or open new one
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then(function (clientList) {
                // If a window is already open, focus it
                for (const client of clientList) {
                    if (client.url.includes('localhost') || client.url.includes('actmgr')) {
                        return client.focus();
                    }
                }
                // Otherwise open a new window
                if (clients.openWindow) {
                    return clients.openWindow('/');
                }
            })
    );
});

