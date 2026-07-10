import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_crop_dryer/models/historical_reading.dart';

class HistoricalReadingService {
  CollectionReference? ref;
  String? _userId;

  String? get userId => _userId;

  HistoricalReadingService(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      ref = FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .collection("historical_readings");
      _userId = userId;
    }
  }

  /// Save a single reading to Firestore
  Future<void> saveReading(HistoricalReading reading) async {
    try {
      await ref!
          .doc(reading.timestamp.toString())
          .set(reading.toMap());
      
      print('✅ Reading saved: ${DateTime.fromMillisecondsSinceEpoch(reading.timestamp)}');
    } catch (e) {
      print('❌ Error saving reading: $e');
      throw Exception('Failed to save reading');
    }
  }

  /// Get readings for today
  Future<List<HistoricalReading>> getReadingsForToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getReadings(
      startDate: startOfDay.millisecondsSinceEpoch,
      endDate: endOfDay.millisecondsSinceEpoch,
    );
  }

  /// Get readings within a timestamp range
  Future<List<HistoricalReading>> getReadings({
    int? startDate,
    int? endDate,
    int? limit,
  }) async {
    try {
      Query query = ref!;

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThan: endDate);
      }

      query = query.orderBy('timestamp', descending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => HistoricalReading.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching readings: $e');
      return [];
    }
  }

  /// Get readings for the last N hours
  Future<List<HistoricalReading>> getReadingsForLastHours(int hours) async {
    final now = DateTime.now();
    final startTime = now.subtract(Duration(hours: hours));
    
    return getReadings(
      startDate: startTime.millisecondsSinceEpoch,
      endDate: now.millisecondsSinceEpoch,
    );
  }

  /// Stream readings in real-time
  Stream<List<HistoricalReading>> streamReadings({
    int? startDate,
    int? limit,
  }) {
    Query query = ref!;

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }

    query = query.orderBy('timestamp', descending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HistoricalReading.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  void updateUserId(String userId) {
    if (userId.isNotEmpty) {
      ref = FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .collection("historical_readings");
      _userId = userId;
    }
  }
}