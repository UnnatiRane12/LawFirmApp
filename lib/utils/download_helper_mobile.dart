// lib/utils/download_helper_mobile.dart

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> downloadFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  Directory? outputDirectory;
  try {
    outputDirectory = await getTemporaryDirectory();
  } catch (e) {
    outputDirectory = Directory.systemTemp;
  }

  final file = File('${outputDirectory.path}/$fileName');
  await file.writeAsBytes(bytes);
  
  // We don't return the result of open, just trigger it.
  // The caller can handle success/error via the snackbar as before.
  await OpenFilex.open(file.path);
}
