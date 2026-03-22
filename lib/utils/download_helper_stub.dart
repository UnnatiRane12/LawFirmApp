// lib/utils/download_helper_stub.dart

import 'dart:async';

Future<void> downloadFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('Cannot download file on this platform.');
}
