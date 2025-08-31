import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Set up message handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get initial message if app was launched from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Subscribe to topics
    await _subscribeToTopics();
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      // Web-specific permission request
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('Permission status: ${settings.authorizationStatus}');
    } else {
      // Mobile permission request
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    // Show in-app notification or update UI
    _showInAppNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    
    // Navigate to relevant screen based on notification data
    if (message.data['type'] == 'expiry_warning') {
      // Navigate to product details or home screen
      _navigateToProduct(message.data['productId']);
    }
  }

  Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to general topics
      // Skip on iOS simulator where APNS token might not be available
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // Check if we have APNS token before subscribing
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          print('APNS token not available, skipping topic subscription');
          return;
        }
      }
      
      await _messaging.subscribeToTopic('all_users');
      await _messaging.subscribeToTopic('expiry_alerts');
    } catch (e) {
      print('Error subscribing to topics: $e');
      // Don't throw error, just log it
    }
  }

  Future<String?> getToken() async {
    try {
      String? token;
      if (kIsWeb) {
        token = await _messaging.getToken(
          vapidKey: 'YOUR_VAPID_KEY', // Replace with your VAPID key for web
        );
      } else {
        token = await _messaging.getToken();
      }
      
      if (token != null) {
        print('FCM Token: $token');
        // Save token to Firestore for sending notifications
        await _saveTokenToDatabase(token);
      }
      
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    // Save token to user document in Firestore
    // This would be called after user authentication
    // Implementation depends on your user management
  }

  Future<void> subscribeToHousehold(String householdId) async {
    await _messaging.subscribeToTopic('household_$householdId');
  }

  Future<void> unsubscribeFromHousehold(String householdId) async {
    await _messaging.unsubscribeFromTopic('household_$householdId');
  }

  // Schedule local notifications for expiry warnings
  Future<void> scheduleExpiryNotifications(String householdId) async {
    try {
      // Get products expiring soon
      final stream = _firestoreService.getExpiringProducts(householdId, 3);
      
      stream.listen((snapshot) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final productName = data['productName'] as String;
          final expiryDate = (data['expiryDate'] as dynamic).toDate() as DateTime;
          final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
          
          if (daysUntilExpiry <= 3 && daysUntilExpiry >= 0) {
            _scheduleNotification(
              productId: doc.id,
              productName: productName,
              daysUntilExpiry: daysUntilExpiry,
            );
          }
        }
      });
    } catch (e) {
      print('Error scheduling expiry notifications: $e');
    }
  }

  void _scheduleNotification({
    required String productId,
    required String productName,
    required int daysUntilExpiry,
  }) {
    // This would integrate with a local notification plugin
    // or trigger a Cloud Function to send FCM
    print('Scheduling notification for $productName - $daysUntilExpiry days until expiry');
  }

  void _showInAppNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    // Show in-app notification UI
    // This could be a snackbar, toast, or custom overlay
    print('In-app notification: $title - $body');
  }

  void _navigateToProduct(String? productId) {
    if (productId == null) return;
    // Navigate to product details screen
    // Implementation depends on your navigation setup
    print('Navigating to product: $productId');
  }

  // Send notification via Cloud Function (server-side)
  static Map<String, dynamic> createNotificationPayload({
    required String title,
    required String body,
    required String productId,
    required String householdId,
    String? imageUrl,
  }) {
    return {
      'notification': {
        'title': title,
        'body': body,
        if (imageUrl != null) 'image': imageUrl,
      },
      'data': {
        'type': 'expiry_warning',
        'productId': productId,
        'householdId': householdId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'topic': 'household_$householdId',
    };
  }
}