import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/feedback_type.dart';
import 'package:period_tracker/exceptions/feedback_exception.dart';
import 'package:period_tracker/services/application_data_service.dart';

/// Sends feedback, feature requests and bug reports to a Discord webhook (URL in .env).
class FeedbackService {
  static const int _descriptionLimit = 4000;
  static const int _fieldLimit = 1000;

  static String _trim(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1)}…';

  static Future<void> send(FeedbackType type, String message, {String? contact, String? errorCode, Object? error, Object? sharedFileContent}) async {
    final String url = dotenv.maybeGet(kDiscordWebhookEnvKey)?.trim() ?? '';
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) throw FeedbackException(kFeedbackNotConfiguredErrorCode);

    final List<Map<String, dynamic>> fields = [];
    void addField(String name, String? value) {
      if (value == null || value.isEmpty) return;
      fields.add({'name': name, 'value': _trim(value, _fieldLimit), 'inline': false});
    }

    addField('Contact', contact);
    addField('Error code', errorCode);
    addField('Error', error?.toString());

    final List<http.MultipartFile> files = [];
    if (type.includesAppData) {
      final PackageInfo info = await PackageInfo.fromPlatform();
      addField(
        'Details',
        'Version: ${info.version}+${info.buildNumber}\n'
            'Database version: $kDatabaseVersion\n'
            'Device: ${Platform.operatingSystem}\n'
            'OS version: ${Platform.operatingSystemVersion}',
      );

      String appContent;
      try {
        appContent = await ApplicationDataService().createBackupFileContent();
      } catch (e) {
        appContent = 'Error generating application data: $e';
      }
      files.add(http.MultipartFile.fromString('files[0]', appContent, filename: 'app_data.json'));

      final String? shared = switch (sharedFileContent) {
        null => null,
        String s => s,
        Object o => jsonEncode(o),
      };
      if (shared != null && shared.isNotEmpty) {
        files.add(http.MultipartFile.fromString('files[1]', shared, filename: 'shared_backup_file.json'));
      }
    }

    final Map<String, dynamic> payload = {
      'embeds': [
        {
          'title': type.title,
          'description': _trim(message.isEmpty ? '(no message)' : message, _descriptionLimit),
          'color': type.color,
          'fields': fields,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      ],
    };

    try {
      final http.BaseRequest request;
      if (files.isEmpty) {
        request = http.Request('POST', uri)
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode(payload);
      } else {
        request = http.MultipartRequest('POST', uri)
          ..fields['payload_json'] = jsonEncode(payload)
          ..files.addAll(files);
      }
      final http.StreamedResponse response = await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FeedbackException(kUnknownErrorCode);
      }
    } on FeedbackException {
      rethrow;
    } on SocketException {
      throw FeedbackException(kNetworkErrorCode);
    } catch (_) {
      throw FeedbackException(kUnknownErrorCode);
    }
  }
}
