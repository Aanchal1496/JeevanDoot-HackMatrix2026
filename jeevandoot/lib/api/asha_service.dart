import 'package:jeevandoot/api/api_client.dart';

class AshaAssignment {
  const AshaAssignment({
    required this.id,
    required this.patientUserId,
    this.patientName,
    this.village,
    this.status,
  });
  final int id;
  final int patientUserId;
  final String? patientName;
  final String? village;
  final String? status;

  factory AshaAssignment.fromJson(Map<String, dynamic> json) => AshaAssignment(
        id: json['id'] as int,
        patientUserId: json['patient_user_id'] as int,
        patientName: json['patient_name'] as String? ?? 'Patient',
        village: json['village'] as String?,
        status: json['status'] as String?,
      );
}

class AshaTask {
  const AshaTask({
    required this.id,
    required this.taskType,
    required this.status,
    this.patientUserId,
    this.dueDate,
  });
  final int id;
  final String taskType;
  final String status;
  final int? patientUserId;
  final String? dueDate;

  factory AshaTask.fromJson(Map<String, dynamic> json) => AshaTask(
        id: json['id'] as int,
        taskType: json['task_type'] as String,
        status: json['status']?.toString() ?? 'pending',
        patientUserId: json['patient_user_id'] as int?,
        dueDate: json['due_date']?.toString(),
      );
}

/// Client for the ASHA worker portal.
class AshaService {
  const AshaService(this._client);
  final ApiClient _client;

  Future<List<AshaAssignment>> assignments() async {
    final json = await _client.get('/asha/assignments') as List<dynamic>;
    return json
        .map((e) => AshaAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AshaTask>> tasks() async {
    final json = await _client.get('/asha/tasks') as List<dynamic>;
    return json
        .map((e) => AshaTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordVitals(int patientId, Map<String, dynamic> data) =>
      _client.post('/asha/patients/$patientId/vitals', data, authenticated: true);

  Future<Map<String, dynamic>> assist(
      int patientId, Map<String, dynamic> data) async {
    final json = await _client.post('/asha/patients/$patientId/assist', data,
        authenticated: true) as Map<String, dynamic>;
    return json;
  }

  Future<void> escalate(int patientId, Map<String, dynamic> data) =>
      _client.post('/asha/patients/$patientId/escalate', data,
          authenticated: true);

  Future<void> updateTask(int taskId, String status) =>
      _client.put('/asha/tasks/$taskId', {'status': status}, authenticated: true);

  Future<void> createTask({int? patientUserId, required String taskType}) =>
      _client.post('/asha/tasks',
          {'patient_user_id': patientUserId, 'task_type': taskType},
          authenticated: true);
}