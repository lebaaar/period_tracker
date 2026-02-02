import 'dart:io';
import 'package:open_mail/open_mail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/email_type.dart';
import 'package:period_tracker/exceptions/email_exception.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/encryption_service.dart';

class EmailService {
  static Future<void> openEmail(EmailType emailType, String? errorCode, {sharedFileContent, Object? error}) async {
    String appContent = '';
    try {
      appContent = await ApplicationDataService().createBackupFileContent();
    } catch (e) {
      appContent = 'Error generating application data: $e';
    }
    final String encodedContent = EncryptionService().base64Encode(appContent);

    String? backupEncodedContent;
    if (sharedFileContent != null && sharedFileContent.toString().isNotEmpty) {
      backupEncodedContent = sharedFileContent.toString();
      backupEncodedContent = EncryptionService().base64Encode(backupEncodedContent.toString());
    }

    final EmailContent emailContent = EmailContent(
      to: [kContactEmail],
      subject: emailType == EmailType.bugReport ? kBugReportEmailSubject : kFeedbackEmailSubject,
      body: emailType == EmailType.bugReport
          ? '''
Hello,\n
${emailType != EmailType.feedback ? "I'm having an issue with Period Tracker." : ""}
${errorCode == null ? "<SPECIFY YOUR ISSUE HERE>" : ""}
${_bugReportEmailDetails(errorCode, await PackageInfo.fromPlatform(), Platform.operatingSystem, Platform.operatingSystemVersion, encodedContent, error: error, backupEncodedContent: backupEncodedContent)}
'''
          : null,
    );

    final OpenMailAppResult result;
    try {
      result = await OpenMail.composeNewEmailInMailApp(nativePickerTitle: 'Select email app', emailContent: emailContent);

      if (!result.didOpen && !result.canOpen) {
        throw EmailException(kNoEmailAppErrorCode);
      }
    } on EmailException {
      rethrow;
    } catch (_) {
      throw EmailException(kUnknownErrorCode);
    }
  }

  static String _bugReportEmailDetails(
    String? errorCode,
    var packageInfo,
    String platformOs,
    String platformOsVersion,
    String encodedContent, {
    Object? error,
    String? backupEncodedContent,
  }) {
    String details = '''\n\n
Development details (please don't remove this, as it helps us diagnose issues faster):\n''';

    if (errorCode != null) {
      details += '[Error code: ${errorCode.toString()}]\n';
    }

    if (error != null) {
      details += '[Error: ${error.toString()}]\n';
    }

    details +=
        '''
[Timestamp: ${DateTime.now()}]
[Version: ${packageInfo.version}+${packageInfo.buildNumber}]
[Database version: $kDatabaseVersion]
[Device: $platformOs]
[OS version: $platformOsVersion]
[Content: $encodedContent]\n''';

    if (backupEncodedContent != null) {
      details += '[Backup content: ${backupEncodedContent.toString()}]\n';
    }

    return details;
  }
}
