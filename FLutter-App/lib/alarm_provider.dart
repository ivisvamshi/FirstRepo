import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:alarm/alarm.dart';
import 'alarmRingScreen.dart';

class AlarmProvider extends ChangeNotifier {
  late SharedPreferences preferences;
  List<Map<String, dynamic>> modelist = [];
  List<String> listofstring = [];
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late BuildContext context;

  Future<void> initialize(BuildContext con) async {
    context = con;
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSinitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSinitialize);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin!.initialize(initializationsSettings, onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'full_screen_channel',
      'Full Screen Notifications',
      description: 'This channel is used for full-screen notifications',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await Alarm.init();
  }

  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('notification payload: $payload');
      final alarmSettings = AlarmSettings.fromJson(jsonDecode(payload));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExampleAlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
    }
  }

  Future<void> getData() async {
    preferences = await SharedPreferences.getInstance();
    List<String>? cominglist = preferences.getStringList("data");
    if (cominglist != null) {
      modelist = cominglist.map((e) => json.decode(e) as Map<String, dynamic>).toList();
      notifyListeners();
    }
  }

  Future<void> setData() async {
    listofstring = modelist.map((e) => json.encode(e)).toList();
    await preferences.setStringList("data", listofstring);
    notifyListeners();
  }

  void setAlarm(String label, String dateTime, bool check, String repeat, int id, int milliseconds) {
    modelist.add({
      'label': label,
      'dateTime': dateTime,
      'check': check,
      'repeat': repeat,
      'id': id,
      'milliseconds': milliseconds
    });
    notifyListeners();
  }

  void editSwitch(int index, bool check) {
    modelist[index]['check'] = check;
    notifyListeners();
  }

 Future<void> scheduleNotification(DateTime dateTime, int randomNumber, String medicineName, String schedule, String dosage, String instructions, bool beforeFood, String imagePath) async {
  int newTime = dateTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
  final alarmSettings = AlarmSettings(
    id: randomNumber,
    dateTime: dateTime,
    assetAudioPath: 'assets/audio/audio.mp3', // Make sure this path is correct
    notificationTitle: 'Medicine Reminder: $medicineName',
    notificationBody: '$medicineName;$dosage;$schedule;$instructions;$beforeFood;$imagePath',
  );

  await Alarm.set(alarmSettings: alarmSettings);

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      'full_screen_channel',
      'Full Screen Notifications',
      channelDescription: 'This channel is used for full-screen notifications',
      sound: RawResourceAndroidNotificationSound("audio"),
      autoCancel: false,
      playSound: true,
      priority: Priority.max,
      importance: Importance.max,
      fullScreenIntent: true,
    ),
  );

  await flutterLocalNotificationsPlugin!.zonedSchedule(
    randomNumber,
    'Medicine Reminder: $medicineName',
    'Dosage: $dosage, Schedule: $schedule, Instructions: $instructions, Before Food: $beforeFood',
    tz.TZDateTime.now(tz.local).add(Duration(milliseconds: newTime)),
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    payload: jsonEncode(alarmSettings),
  );
}

  Future<void> cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin!.cancel(notificationId);
    await Alarm.stop(notificationId);
  }
}
