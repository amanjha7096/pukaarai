import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking/data/models/activity_model.dart';

void main() {
  group('ActivityModel.fromJson', () {
    test('parses String createdAt', () {
      final json = {
        'id': 'abc',
        'type': 'steps',
        'value': 5000.0,
        'note': null,
        'createdAt': '2026-05-06T12:00:00.000',
      };
      final model = ActivityModel.fromJson(json);

      expect(model.id, 'abc');
      expect(model.type, 'steps');
      expect(model.value, 5000.0);
      expect(model.note, isNull);
      expect(model.createdAt, DateTime.parse('2026-05-06T12:00:00.000'));
    });

    test('parses Timestamp createdAt', () {
      final dt = DateTime(2026, 5, 6, 12, 0);
      final json = {
        'id': 'def',
        'type': 'water',
        'value': 500.0,
        'note': 'morning',
        'createdAt': Timestamp.fromDate(dt),
      };
      final model = ActivityModel.fromJson(json);

      expect(model.id, 'def');
      expect(model.type, 'water');
      expect(model.value, 500.0);
      expect(model.note, 'morning');
      expect(model.createdAt, dt);
    });

    test('defaults value to 0.0 when null', () {
      final json = {
        'id': 'ghi',
        'type': 'sleep',
        'value': null,
        'createdAt': '2026-05-06T00:00:00.000',
      };
      final model = ActivityModel.fromJson(json);

      expect(model.value, 0.0);
    });

    test('coerces int value to double', () {
      final json = {
        'id': 'jkl',
        'type': 'heart',
        'value': 75,
        'createdAt': '2026-05-06T00:00:00.000',
      };
      final model = ActivityModel.fromJson(json);

      expect(model.value, 75.0);
      expect(model.value, isA<double>());
    });

    test('preserves note field when present', () {
      final json = {
        'id': 'mno',
        'type': 'calories',
        'value': 350.0,
        'note': 'lunch salad',
        'createdAt': '2026-05-06T13:00:00.000',
      };
      final model = ActivityModel.fromJson(json);

      expect(model.note, 'lunch salad');
    });
  });

  group('ActivityModel.toJson', () {
    test('serializes all fields', () {
      final dt = DateTime(2026, 5, 6, 12, 0);
      final model = ActivityModel(
        id: 'test1',
        type: 'calories',
        value: 350.5,
        note: 'lunch',
        createdAt: dt,
      );
      final json = model.toJson();

      expect(json['id'], 'test1');
      expect(json['type'], 'calories');
      expect(json['value'], 350.5);
      expect(json['note'], 'lunch');
      expect(json['createdAt'], isA<Timestamp>());
      expect((json['createdAt'] as Timestamp).toDate(), dt);
    });

    test('note is null when not provided', () {
      final model = ActivityModel(
        id: 'n1',
        type: 'water',
        value: 250.0,
        createdAt: DateTime(2026, 5, 6),
      );
      expect(model.toJson()['note'], isNull);
    });
  });

  group('ActivityModel round-trip', () {
    test('fromJson(toJson()) preserves all values', () {
      final original = ActivityModel(
        id: 'rt1',
        type: 'water',
        value: 250.0,
        note: null,
        createdAt: DateTime(2026, 5, 6, 8, 30),
      );
      final restored = ActivityModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.value, original.value);
      expect(restored.note, original.note);
      expect(restored.createdAt, original.createdAt);
    });

    test('round-trip preserves note', () {
      final original = ActivityModel(
        id: 'rt2',
        type: 'calories',
        value: 500.0,
        note: 'breakfast',
        createdAt: DateTime(2026, 5, 6, 7, 0),
      );
      final restored = ActivityModel.fromJson(original.toJson());

      expect(restored.note, 'breakfast');
    });
  });
}
