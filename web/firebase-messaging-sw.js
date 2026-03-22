importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyC96DzJYuZNV7-aOhevG-j-ijz7H2Fy2Lo",
  authDomain: "soka-planner.firebaseapp.com",
  projectId: "soka-planner",
  storageBucket: "soka-planner.firebasestorage.app",
  messagingSenderId: "777301808825",
  appId: "1:777301808825:web:af2218099b72f386bf2d68",
});

const messaging = firebase.messaging();
