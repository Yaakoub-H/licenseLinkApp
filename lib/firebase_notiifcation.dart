import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class MyFireBaseCloudMessaging {
  static Future<String> getAccessToken() async {
    final serverToken = {
      "type": "service_account",
      "project_id": "licenselink-daeff",
      "private_key_id": "458b89e6dac4cfbcc755d247b8aa3fed9cf1aac4",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCR9caELrAjWRQn\npYzWZLSRtBp6YR3qnSaZrkKaC17c+RmFLXavGIiJm2tpQkvDhcy3cY2EatQdKSAz\n2kLM7+QzZbReLs/zhjuKBIMHBUuF9xM8TBIBfIhXQDlMnIaMOzAXSrPfLaJvuH7i\nQhXh7MXm5W6BydxpgAxOXUbvicYMNsBm0ibWaw9EoBWurv2+lDvtgHtZIyzDb/U3\n6yUr35bVHv2EKjTbJGY2AlYXbs6sKsrdc0U6RPPNq5VJBpZFwSqxXBTF8yrzSn+J\nhHDKKNm/Qjg5G1T2fk8LYkSOIsiL/kIHPalIHMFybk2WxLsaRUszF4qNiVncy7ur\nzUMjnH4DAgMBAAECggEABVijx1awc/MA1nztXjL9HDMlHyNshZnw/oMQBHVzKZPk\nN+kU5k/3PFcZhZb8kHJXr8Z0gQuqrlDB0bRmavxEdw98HlEHo+tgRetpYznx7LvC\nlBxTMoO9uLhtAN3g3cUTO18snHme8AmpeB8kjwxtqUnxFMbwkFq02K/497ArtWnD\n0WsPpArPBcGOhvzKZD1gGWxUgMCsofQODX7IFuLmAHWWvwtydYkJ750+gEoUio+x\nihkL969m185/QLtkaJOoQz3rjcO7egRAoyqfiEUgT3u7GiZnMJSu4FLOTdDoyYdw\n6/PSp7RsIcHY7oLK5kCLnIipoBpm0fyXXOrJ3qS1lQKBgQDJB4RiynBD0QSlzJAJ\negx43TY9RFwTs++rZcqc99XgZrzZ30IIIzqOHBVxyRAuS3NBZhLZtGnOHSiqv8Ps\nb/jNRVUlj6Cr+m53w807no9vyz4QwlJ7oSNAT8gmOLyOUfOTLY+iCv/rk9fi9PaB\nERcGGZi8RSUqJHGB/qbsZtgHDwKBgQC530o9gPlZHzCMkOCUf2xDzhJDFapQ7bpo\nsGRLqiXg8bTR8LXkM7pWTHSjTYH/RrlW1Rugm2mDuklSYijk0BH3ewthyC5sp/H7\nkfcergIu95WbqnQHx19GSzuQiWtINCblTbx3lfBveL6MSyIPDaprKchfnF74EEpM\nSPDuxCu5zQKBgCc5G0B3RS5GMwTyg8wFjzdp2fJcSybg/ctQYhb8WDOfeAt+fxC9\nZuhhXGHGHC0cNZG2C8mEZPx9PfkKz3xrYH0UoQdiHbRQeYtOndWbG1txqVt1vsg2\naX1b0655dXjDTqYRxquUP9jEEORMbWhDYF2lUuKxDw5I7Ai0GfeYHWBLAoGAecoj\nXRVrTMgxCYnMfcDYcb1PHgHOLWT3pa0eqq18UF5P+tfcdwCl8fH64x3gNiJjQtA0\nYBI1GwkvDfofjX4Ap8ZJ+PIv6SZKWmqUH9gouhmkP/F6QbaTaP3Ws6g3UYJKkilT\nepAWkRPu1wJL+M0dg0ZHcs6FM8mIxV9t7yU++WkCgYByb/WNsFms/c2lb+ddS1Xw\n0bpqOFuXcl/lHdEK/mh/2dqSI1/qEd1XLo1uUSJsUKvAklHpfgQmXG0NGpW1gYXv\nHOF/M4xm8BiGY9mQi7xGedubHz4gMTUdacEBFhRcAuBLqBxcfAsWo6lxUVwkML5x\nZ/1WLZjtJwuCPbwUHhkK8w==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@licenselink-daeff.iam.gserviceaccount.com",
      "client_id": "111087667128178777194",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40licenselink-daeff.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    // Get access token
    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serverToken),
          scopes,
          http.Client(),
        );
    return credentials.accessToken.data;
  }

  static Future<void> sendNotificationToUser(
    String deviceToken,
    String receiverUid,
    BuildContext context,
    String title,
    String description,
    String notificationID,
  ) async {
    print('response: $deviceToken');

    final String serverKey = await getAccessToken();
    final postUrl =
        'https://fcm.googleapis.com/v1/projects/licenselink-daeff/messages:send';

    final Map<String, dynamic> message = {
      "message": {
        "token": deviceToken,
        "notification": {"title": title, "body": description},
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done",
          "notificationID": notificationID,
        },
      },
    };

    final response = await http.post(
      Uri.parse(postUrl),
      body: jsonEncode(message),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
    );
    if (response.statusCode == 200) {
      print('Notification sent');

      // Store the notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userUid': receiverUid,
        'title': title,
        'description': description,
        'notificationID': notificationID,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      print('Notification not sent');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }
}
