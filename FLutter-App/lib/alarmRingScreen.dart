import 'package:audioplayers/audioplayers.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class ExampleAlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const ExampleAlarmRingScreen({Key? key, required this.alarmSettings}) : super(key: key);

  @override
  _ExampleAlarmRingScreenState createState() => _ExampleAlarmRingScreenState();
}

class _ExampleAlarmRingScreenState extends State<ExampleAlarmRingScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playAlarmSound();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAlarmSound() async {
    await _audioPlayer.play(AssetSource(widget.alarmSettings.assetAudioPath));
  }

  @override
  Widget build(BuildContext context) {
    final alarmDetails = widget.alarmSettings.notificationBody.split(';');
    final medicineName = alarmDetails[0];
    final dosage = alarmDetails[1];
    final schedule = alarmDetails[2];
    final instructions = alarmDetails[3];
    final beforeFood = alarmDetails[4];
    final imagePath = alarmDetails[5];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Time for your Medicine",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 3.0,
                          color: Colors.black45,
                        ),
                      ],
                    ),
              ),
              Column(
                children: [
                  if (imagePath.isNotEmpty)
                    SizedBox(
                      width: 400,
                      height: 550,
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  Text(
                    'Medicine Name: $medicineName',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                  ),
                  Text(
                    'Dosage: $dosage',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                  ),
                  Text(
                    'Instructions: $instructions',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                  ),
                  Text(
                    'Schedule: $schedule',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                  ),
                  Text(
                    beforeFood == 'true' ? 'Before Food' : 'After Food',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                  ),
                ],
              ),
              Center(
                child: RawMaterialButton(
                  onPressed: () {
                    Alarm.stop(widget.alarmSettings.id)
                        .then((_) => Navigator.pop(context));
                  },
                  fillColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                  child: Text(
                    "Stop",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
