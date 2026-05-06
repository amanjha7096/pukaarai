import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String type;
  final double value;
  final String? note;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.type,
    required this.value,
    this.note,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    final createdAt = created is Timestamp
        ? created.toDate()
        : DateTime.parse(created as String);

    return ActivityModel(
      id: json['id'] as String,
      type: json['type'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
