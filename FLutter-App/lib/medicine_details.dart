import 'dart:io';

import 'package:flutter/material.dart';

class MedicineDetailsPage extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailsPage({Key? key, required this.medicine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicine['name'],style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (medicine['imagePath'].isNotEmpty)
                Image.file(File(medicine['imagePath'])),
              const SizedBox(height: 16),
              Text('Dosage: ${medicine['dosage']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
              const SizedBox(height: 16),
              Text('Schedule: ${medicine['schedule'].join(', ')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
              const SizedBox(height: 16),
              Text('Timings: ${medicine['times'].join(', ')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
              const SizedBox(height: 16),
              Text('Before/After Food: ${medicine['beforeFood'] ? 'Before Food' : 'After Food'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
              const SizedBox(height: 16),
              Text('Instructions: ${medicine['instructions']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
