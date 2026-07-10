import 'package:flutter/material.dart';

class Crop {
  final String? id; 
  final String name;
  final IconData iconData;
  final double minTemp;
  final double maxTemp;

  Crop({this.id, required this.name, required this.iconData, required this.minTemp, required this.maxTemp});

  // Updated fromJson to accept the document ID
  factory Crop.fromMap(Map<String, dynamic> json, String? id) {
    return Crop(
      id: id,
      name: json['name'] ?? '',
      iconData: IconData(json['iconData'] ?? 0xe047, fontFamily: 'MaterialIcons'), // Use const default icon code
      minTemp: (json['minTemp'] ?? 0).toDouble(),
      maxTemp: (json['maxTemp'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconData': iconData.codePoint,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      // Firestore automatically handles timestamps if you need them,
      // or you can add a FieldValue.serverTimestamp() here.
      // 'timestamp': FieldValue.serverTimestamp(), // Requires 'package:cloud_firestore/cloud_firestore.dart';
    };
  }
}