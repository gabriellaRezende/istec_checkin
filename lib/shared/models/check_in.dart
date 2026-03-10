
class CheckInRecord {
  final String id;
  final String code;
  final DateTime timestamp;
  final String location;
  final bool isSuccess;

  CheckInRecord({
    required this.id,
    required this.code,
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
    id: json['id'] ?? '',
    code: json['code'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    location: json['location'] ?? '',
    isSuccess: json['isSuccess'] ?? false,
  );
}
