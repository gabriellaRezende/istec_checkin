
class CheckInRecord {
  final String id;
  final String code;
  final DateTime timestamp;
  final String location;
  final String status;


  CheckInRecord({
    required this.id,
    required this.code,
    required this.timestamp,
    required this.location,
    required this.status,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPending => status.toLowerCase() == 'pending';

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'location': location,
    'staus': status,
  };

  factory CheckInRecord.fromJson(Map<String, dynamic> json){
    return CheckInRecord(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    location: json['location'] ?? '',
    status: (json['status'] ?? 'pending' ).toString(),
    );
  }
}
