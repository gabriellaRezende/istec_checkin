
class CheckInRecord {
  final String id;
  final DateTime timestamp;
  final String location;
  final bool isSuccess;

  CheckInRecord({
    required this.id,
    required this.timestamp,
    required this.location,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'location': location,
    'isSuccess': isSuccess,
  };

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    location: json['location'],
    isSuccess: json['isSuccess'],
  );
}
