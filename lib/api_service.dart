// lib/api_service.dart
import 'dart:convert';
import 'dart:io'; // Used for SocketException
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ruko_mobile_app/models/task.dart'; // Assuming Task.fromJson is updated for safe parsing
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

class ApiService {
  // static const String _baseUrl = 'https://api.sarlpro.com/api';
  static const String _baseUrl = 'https://api.sarlpro.com/api';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'api_token');
  }

  // Helper method to handle common API exceptions
  Exception _handleError(dynamic e) {
    print('API Error: ${e.toString()}');
    if (e is SocketException) {
      return Exception(
        'Failed to connect to the server. Please check your network connection.',
      );
    }
    // This will catch CORS issues in a web environment, which often manifest as ClientException
    if (e.toString().contains('XMLHttpRequest error')) {
      return Exception(
        'A network error occurred. This may be a CORS issue. Please contact support.',
      );
    }
    return Exception('An unexpected error occurred: ${e.toString()}');
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Accept': 'application/json'},
            body: {'email': email, 'password': password},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        if (token != null) {
          await _storage.write(key: 'api_token', value: token);
          return true;
        }
      }
      return false;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCreateTaskFormData() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/form-data/create-task'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load form data');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> createTask(Map<String, dynamic> taskData) async {
    // Changed return type to Future<int>
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(taskData),
      );

      if (response.statusCode == 201) {
        // ✅ PARSE AND RETURN THE NEW TASK ID
        final responseBody = json.decode(response.body);
        return responseBody['task_id'];
      } else {
        print('Failed to create task. Status: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception('Failed to create task. Check console for details.');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateTask(int taskId, Map<String, dynamic> taskData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(taskData),
      );

      if (response.statusCode != 200) {
        print('Failed to update task. Status: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception('Failed to update task. Check console for details.');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        // The safe parsing logic is handled inside the Task.fromJson factory constructor
        return body.map((dynamic item) => Task.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTaskDetails(int taskId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load task details');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/statuses'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load statuses');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateTaskStatus(int taskId, int statusId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/update-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status_id': statusId}),
      );
      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user info');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // The backend returns a list of notifications.
        return jsonDecode(response.body);
      } else {
        // Handle potential server errors
        throw Exception(
          'Failed to load notifications. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // ✅ FIX: Check for 204 (No Content) as the success status code.
      if (response.statusCode != 204) {
        throw Exception(
          'Failed to delete notification on server. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    // First, try to delete the FCM token from the server.
    try {
      // We need to import firebase_messaging to get the token here.
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await deleteFcmToken(fcmToken);
      }
    } catch (e) {
      print('Failed to get FCM token on logout: $e');
    }

    // Then, delete the local auth token to complete the logout.
    await _storage.delete(key: 'api_token');
  }

  Future<Map<String, dynamic>> createComment(
    int taskId,
    String description,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'description': description}),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Failed to create comment. Status Code: ${response.statusCode}');
        print('Server Response: ${response.body}');
        throw Exception('Failed to create comment. Check console for details.');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateComment(int commentId, String description) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await http.put(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'description': description}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update comment.');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment.');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print('Failed to delete task. Status: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception('Failed to delete task. Check console for details.');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User is not authenticated.');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/manual-change-password'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'current_password': currentPassword,
              'new_password': newPassword,
              'new_password_confirmation': newPasswordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['error'] ??
            errorBody['message'] ??
            'An unknown error occurred.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> uploadAttachment(int taskId, PlatformFile file) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/tasks/$taskId/attachments'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // ✅ --- THE FIX IS HERE ---
      // Conditionally create the MultipartFile based on the platform.
      http.MultipartFile multipartFile;

      if (kIsWeb) {
        // For web, use `fromBytes` with the file's byte data.
        multipartFile = http.MultipartFile.fromBytes(
          'attachment', // This field name must match your Laravel API
          file.bytes!,
          filename: file.name,
        );
      } else {
        // For mobile (iOS/Android), use `fromPath` with the file's path.
        multipartFile = await http.MultipartFile.fromPath(
          'attachment', // This field name must match your Laravel API
          file.path!,
          filename: file.name,
        );
      }

      // Add the correctly created file to the request.
      request.files.add(multipartFile);

      final response = await request.send();

      if (response.statusCode != 201) {
        final responseBody = await response.stream.bytesToString();
        print('Failed to upload file. Status: ${response.statusCode}');
        print('Body: $responseBody');
        throw Exception('Failed to upload file: ${file.name}');
      }
    } catch (e) {
      throw Exception('Failed to upload ${file.name}: ${e.toString()}');
    }
  }

  Future<void> storeFcmToken(String token) async {
    try {
      final authToken = await _getToken();
      if (authToken == null) return; // Don't try if not logged in

      await http.post(
        Uri.parse('$_baseUrl/fcm-tokens'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token': token}),
      );
    } catch (e) {
      // We don't throw an error here because failing to store the token
      // shouldn't crash the app. We just log it.
      print('ApiService: Failed to store FCM token. Error: $e');
    }
  }

  Future<void> deleteFcmToken(String token) async {
    try {
      final authToken = await _getToken();
      if (authToken == null) return;

      await http.post(
        Uri.parse('$_baseUrl/fcm-tokens/delete'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token': token}),
      );
    } catch (e) {
      print('ApiService: Failed to delete FCM token. Error: $e');
    }
  }
}
