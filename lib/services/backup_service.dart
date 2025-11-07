import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weighing_system/utils/debugging_methods.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<int?> uploadToS3WithDio(File backup) async {
    const seperater = '-';
    final date = DateTime.now();
    final dateString = date.year.toString() +
        seperater +
        date.month.toString() +
        seperater +
        date.day.toString();
    final accessKey = dotenv.env['API_KEY'];
    final secretKey = dotenv.env['API_SECRET'];

    final accessEKey = dotenv.env['API_KEY'];
    final secretEKey = dotenv.env['API_SECRET'];
    printd(accessEKey ?? 'no access key is there');
    printd(secretEKey ?? 'no access key is there');
    const region = 'us-east-1';
    const bucket = 'weighting-dahrouj-system';
    final objectKey = 'backups/${dateString}/database.db';
    const service = 's3';

    // 1️⃣ Read the binary file
    final fileBytes = await backup.readAsBytes();

    // 2️⃣ Compute payload hash
    final payloadHash = sha256.convert(fileBytes).toString();

    final now = DateTime.now().toUtc();
    final amzDate = _formatDate(now, withTime: true);
    final dateStamp = _formatDate(now, withTime: false);

    final host = '$bucket.s3.$region.amazonaws.com';
    final url = 'https://$host/$objectKey';

    final canonicalHeaders =
        'content-type:application/octet-stream\nhost:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
    final signedHeaders = 'content-type;host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest =
        'PUT\n/$objectKey\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

    final signingKey = _getSignatureKey(secretKey!, dateStamp, region, service);
    final signature =
        Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    final authorization =
        '$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    final headers = {
      'Content-Type': 'application/octet-stream',
      'Host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'Authorization': authorization,
    };

    final dio = Dio();

    try {
      final response = await dio.put(
        url,
        data: fileBytes,
        options: Options(headers: headers),
      );
      printd('✅ Upload success: ${response.statusCode}');
      return 1;
    } on DioException catch (e) {
      printd('❌ Upload failed');

      // Detailed diagnostics
      printd('Status code: ${e.response?.statusCode}');
      printd('Status message: ${e.response?.statusMessage}');
      printd('Server response: ${e.response?.data}');
      printd('Request: ${e.requestOptions.method} ${e.requestOptions.uri}');
      printd('Headers: ${e.requestOptions.headers}');
      printd('Error type: ${e.type}');
      printd('Error message: ${e.message}');
      rethrow;
    } catch (e, st) {
      printd('Unexpected error: $e');
      printd('Stacktrace: $st');
      rethrow;
    }
  }

  String _formatDate(DateTime date, {required bool withTime}) {
    if (withTime) {
      return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}T'
          '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}Z';
    } else {
      return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    }
  }

  List<int> _getSignatureKey(
      String key, String dateStamp, String region, String service) {
    final kDate = _hmac(utf8.encode('AWS4$key'), utf8.encode(dateStamp));
    final kRegion = _hmac(kDate, utf8.encode(region));
    final kService = _hmac(kRegion, utf8.encode(service));
    final kSigning = _hmac(kService, utf8.encode('aws4_request'));
    return kSigning;
  }

  List<int> _hmac(List<int> key, List<int> message) {
    final hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(message).bytes;
  }
}
