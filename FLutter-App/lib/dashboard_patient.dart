
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'medicine_details.dart';
import 'alarm_provider.dart';
import 'package:provider/provider.dart'; 

// ignore: must_be_immutable
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showMedicineForm = false;
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeControllers = {
    'Morning': TextEditingController(),
    'Afternoon': TextEditingController(),
    'Night': TextEditingController(),
  };
  List<String> _schedules = [];
  bool _beforeFood = true;
  final _instructionsController = TextEditingController();
  XFile? _medicineImage;
  List<Map<String, dynamic>> _savedMedicines = [];

  

  @override
  void initState() {
    super.initState();
    _loadMedicineData();
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    alarmProvider.initialize(context);
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final savedImagePath = await _saveImage(File(image.path));
      setState(() {
        _medicineImage = XFile(savedImagePath);
      });
    }
  }


  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }


Future<String> _saveImage(File image) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final imagePath = path.join(directory.path, 'MedicineImages');
        final imageDirectory = Directory(imagePath);
        if (!await imageDirectory.exists()) {
          await imageDirectory.create(recursive: true);
        }

        final bytes = await image.readAsBytes();
        final fileName = path.basenameWithoutExtension(image.path) + path.extension(image.path);
        final newImage = File(path.join(imageDirectory.path, fileName));
        await newImage.writeAsBytes(bytes);

        return newImage.path;
      } else {
        return '';
      }
    } catch (e) {
      print('Error saving image: $e');
      return '';
    }
  }


  Future<void> _appendMedicineData(String jsonData) async {
    try {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/medicines.json');
      if (await file.exists()) {
        final existingData = await file.readAsString();
        final List<dynamic> existingList = jsonDecode(existingData);
        existingList.add(jsonDecode(jsonData));
        await file.writeAsString(jsonEncode(existingList));
      } else {
        await file.writeAsString('[$jsonData]');
      }
    } catch (e) {
      print('Error appending medicine data: $e');
    }
  }

  Future<void> _loadMedicineData() async {
    try {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/medicines.json');
      if (await file.exists()) {
        final existingData = await file.readAsString();
        final List<dynamic> existingList = jsonDecode(existingData);
        setState(() {
          _savedMedicines = List<Map<String, dynamic>>.from(existingList);
        });
      }
    } catch (e) {
      print('Error loading medicine data: $e');
    }
  }

  Future<void> _updateMedicineData() async {
    try {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/medicines.json');
      if (await file.exists()) {
        await file.writeAsString(jsonEncode(_savedMedicines));
      }
    } catch (e) {
      print('Error updating medicine data: $e');
    }
  }
  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, String schedule) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      useRootNavigator: false,
    );
    if (picked != null) {
      final formattedTime = _formatTime(picked);
      setState(() {
        _timeControllers[schedule]?.text = formattedTime;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // uses a 12-hour format
    return format.format(dt);
  }

 Future<void> _setMedicineReminder(String name, String dosage, String schedule, String time) async {
  final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
  final now = DateTime.now();
  final dateTime = DateFormat.jm().parse(time);
  DateTime alarmDateTime = DateTime(now.year, now.month, now.day, dateTime.hour, dateTime.minute);

  // Ensure the alarm time is in the future
  if (alarmDateTime.isBefore(now)) {
    alarmDateTime = alarmDateTime.add(Duration(days: 1));
  }

  // Create unique id for each notification
  final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Assuming these variables are available within your class
  final instructions = _instructionsController.text;
  final beforeFood = _beforeFood;
  final imagePath = _medicineImage?.path ?? '';

  await alarmProvider.scheduleNotification(alarmDateTime, id, name, schedule, dosage, instructions, beforeFood, imagePath);

  // Save the alarm details (you can add other details as needed)
  alarmProvider.setAlarm(name, alarmDateTime.toIso8601String(), true, schedule, id, alarmDateTime.millisecondsSinceEpoch);
  alarmProvider.getData();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Patient Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _showMedicineForm ? _buildMedicineForm() : _buildSavedMedicines(),
            ),
            _buildAddMedicineButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineForm() {
    return Form(
      child: ListView(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Medicine Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _dosageController,
            decoration: const InputDecoration(
              labelText: 'Dosage',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule'),
              CheckboxListTile(
                title: const Text('Morning'),
                value: _schedules.contains('Morning'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _schedules.add('Morning');
                    } else {
                      _schedules.remove('Morning');
                    }
                  });
                },
              ),
              if (_schedules.contains('Morning'))
                TextFormField(
                  controller: _timeControllers['Morning'],
                  readOnly: true,
                  onTap: () => _selectTime(context, 'Morning'),
                  decoration: const InputDecoration(
                    labelText: 'Time for Morning (AM/PM)',
                    border: OutlineInputBorder(),
                  ),
                ),
              CheckboxListTile(
                title: const Text('Afternoon'),
                value: _schedules.contains('Afternoon'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _schedules.add('Afternoon');
                    } else {
                      _schedules.remove('Afternoon');
                    }
                  });
                },
              ),
              if (_schedules.contains('Afternoon'))
                TextFormField(
                  controller: _timeControllers['Afternoon'],
                  readOnly: true,
                  onTap: () => _selectTime(context, 'Afternoon'),
                  decoration: const InputDecoration(
                    labelText: 'Time for Afternoon (AM/PM)',
                    border: OutlineInputBorder(),
                  ),
                ),
              CheckboxListTile(
                title: const Text('Night'),
                value: _schedules.contains('Night'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _schedules.add('Night');
                    } else {
                      _schedules.remove('Night');
                    }
                  });
                },
              ),
              if (_schedules.contains('Night'))
                TextFormField(
                  controller: _timeControllers['Night'],
                  readOnly: true,
                  onTap: () => _selectTime(context, 'Night'),
                  decoration: const InputDecoration(
                    labelText: 'Time for Night (AM/PM)',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Before Food'),
              Switch(
                value: _beforeFood,
                onChanged: (bool value) {
                  setState(() {
                    _beforeFood = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _instructionsController,
            decoration: const InputDecoration(
              labelText: 'Instructions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showImageSourceActionSheet(context),
            child: const Text('Upload Image'),
          ),
          if (_medicineImage != null) Image.file(File(_medicineImage!.path)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
            final name = _nameController.text;
            final dosage = _dosageController.text;
            if (name.isNotEmpty && dosage.isNotEmpty && _schedules.isNotEmpty) {
              for (var schedule in _schedules) {
                final time = _timeControllers[schedule]?.text;
                if (time != null && time.isNotEmpty) {
                  await _setMedicineReminder(name, dosage, schedule, time);
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reminder set for $name at $time')),
                  );
               }
              }
              String imagePath = '';
              if (_medicineImage != null) {
                imagePath = await _saveImage(File(_medicineImage!.path));
                if (imagePath.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save image')),
                  );
                  return;
                }
              } 
              final medicineData = {
                'name': _nameController.text,
                'dosage': _dosageController.text,
                'schedule': _schedules,
                'times': _schedules.map((schedule) => _timeControllers[schedule]?.text).toList(),
                'beforeFood': _beforeFood,
                'instructions': _instructionsController.text,
                'imagePath': imagePath,
                'taken': false,  // Add the new field here
              };
              final jsonData = jsonEncode(medicineData);
              await _appendMedicineData(jsonData);
              await _loadMedicineData();
              setState(() {
                _showMedicineForm = false;
                _nameController.clear();
                _dosageController.clear();
                _timeControllers.forEach((key, controller) {
                  controller.clear();
                });
                _schedules.clear();
                _beforeFood = true;
                  _instructionsController.clear();
                _medicineImage = null;
              });
              }
              else {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please fill all required fields')),
                );
              }
            },
            child: const Text('Save Medicine'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMedicines() {
    return ListView.builder(
      itemCount: _savedMedicines.length,
      itemBuilder: (context, index) {
        final medicine = _savedMedicines[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: medicine['imagePath'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.file(
                      File(medicine['imagePath']),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    child: Text((index + 1).toString()),
                  ),
            title: Text(
              '${index + 1}. ${medicine['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${medicine['dosage']} - ${medicine['schedule'].join(', ')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(medicine['beforeFood'] ? 'Before Food' : 'After Food'),
                Checkbox(
                  value: medicine['taken'],
                  onChanged: (bool? value) {
                    setState(() {
                      medicine['taken'] = value ?? false;
                      _updateMedicineData();
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineDetailsPage(medicine: medicine),
                ),
              );
            },
          ),
        );
      },
    );
  }

Widget _buildAddMedicineButton() {
  return SizedBox( 
    height: 60.0,  // Increases the height of the button
    child: ElevatedButton(
      onPressed: () {
        setState(() {
          _showMedicineForm = true;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan.shade400,  // Changes the background color of the button
        foregroundColor: Colors.white,  // Changes the text color of the button
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),  // Increases the font size
      ),
      child: const Text('Add Medicine'),
    ),
  );
}

}
