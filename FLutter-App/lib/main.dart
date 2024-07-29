import 'dart:convert';
import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'dashboard_patient.dart';
import 'alarm_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  initializeNotifications();
  runApp(MyApp());
}

void initializeNotifications() async {
  var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
  var iOSinitialize = const DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(android: androidInitialize, iOS: iOSinitialize);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: (response) {
    // Handle notification response
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlarmProvider(),
      child: MaterialApp(
        title: 'Solikin',
        theme: ThemeData(
          primarySwatch: Colors.cyan,
        ),
        home: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    alarmProvider.initialize(context);

    _controller.forward().whenComplete(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash1.jpg',
            fit: BoxFit.cover,
          ),
          const Positioned(
            bottom: 260,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SOLIKIN',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Personalized Health care',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  late Future<String?> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _getUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions(context);
    });
  }

  Future<void> _saveName() async {
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/user_name.json');
    final userData = jsonEncode({'name': _nameController.text});
    await file.writeAsString(userData);
    setState(() {
      _userNameFuture = Future.value(_nameController.text);
    });
  }

  Future<String?> _getUserName() async {
    try {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/user_name.json');
      if (await file.exists()) {
        final userData = await file.readAsString();
        final data = jsonDecode(userData) as Map<String, dynamic>;
        return data['name'] as String?;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Set<Permission> _requestedPermissions = {};

  Future<void> checkPermission(Permission permission, BuildContext context) async {
    if (_requestedPermissions.contains(permission)) {
      return;
    }

    _requestedPermissions.add(permission);
    if (permission == Permission.manageExternalStorage) {
      if (await Permission.manageExternalStorage.isDenied) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Storage Permission'),
            content: Text('Please allow storage permission to store your details.'),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (await _requestStoragePermission()) {
                    setState(() {});
                    _requestNextPermission(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Storage permissions are required to save your data in your device.'),
                    ));
                  }
                },
              ),
            ],
          ),
        );
      }
    } else if (permission == Permission.systemAlertWindow) {
      if (await Permission.systemAlertWindow.isDenied) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Display Over Other Apps Permission'),
            content: Text(
                'Please grant the Display Over Other Apps permission for getting your reminders, please follow these steps:\n\n1. Tap "OK"\n2. You will be directed to "Display Over Other Apps"\n3. Select "Solikin"\n4. Tap "Allow" or press the toggle button'),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final intent = AndroidIntent(
                    action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
                  );
                  await intent.launch();
                  if (await _requestSystemAlertWindowPermission()) {
                    _requestNextPermission(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Display Over Other Apps permission is required to use this app'),
                    ));
                  }
                },
              ),
            ],
          ),
        );
      }
    } else {
      final status = await permission.request();
      if (status.isGranted) {
        _requestNextPermission(context);
      } else if (status.isDenied || status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission for $permission is required to use this app')),
        );
      }
    }
  }

  void _requestNextPermission(BuildContext context) async {
    final permissions = [
      Permission.camera,
      Permission.notification,
      Permission.photos,
      Permission.manageExternalStorage,
      Permission.systemAlertWindow,
      Permission.scheduleExactAlarm,
    ];
    for (var permission in permissions) {
      if (_requestedPermissions.contains(permission)) {
        continue;
      }
      final status = await permission.status;
      if (status != PermissionStatus.granted) {
        _requestedPermissions.add(permission);
        await _requestPermission(permission, context);
        break;
      }
    }
  }

  Future<void> _requestPermissions(BuildContext context) async {
    final permissions = [
      Permission.camera,
      Permission.notification,
      Permission.photos,
      Permission.manageExternalStorage,
      Permission.systemAlertWindow,
      Permission.scheduleExactAlarm,
    ];

    for (var permission in permissions) {
      await checkPermission(permission, context);
    }
  }

  Future<void> _requestPermission(Permission permission, BuildContext context) async {
    if (await permission.isGranted) {
      return;
    }
    await checkPermission(permission, context);
  }

  Future<bool> _requestStoragePermission() async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt >= 30) {
      var re = await Permission.manageExternalStorage.request();
      return re.isGranted;
    } else {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      } else {
        var result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      }
    }
  }

  Future<bool> _requestSystemAlertWindowPermission() async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt >= 23) {
      var re = await Permission.systemAlertWindow.request();
      return re.isGranted;
    } else {
      if (await Permission.systemAlertWindow.isGranted) {
        return true;
      } else {
        var result = await Permission.systemAlertWindow.request();
        return result.isGranted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome To Solikin'),
      ),
      body: FutureBuilder<String?>(
        future: _userNameFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading user data'),
            );
          } else {
            final userName = snapshot.data;
            if (userName == null) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveName,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardPage()),
                    );
                  },
                  child: Text('Welcome $userName, View Medicines'),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
