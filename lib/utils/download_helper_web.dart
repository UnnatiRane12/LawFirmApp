// lib/utils/download_helper_web.dart

import 'dart:async';
import 'dart:html' as html;

Future<void> downloadFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
