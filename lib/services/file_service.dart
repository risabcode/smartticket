// lib/services/file_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileService {
  /// Let user select one or more .json files and return a list of file contents.
  Future<List<String>> pickJsonFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return [];

    final contents = <String>[];
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final file = File(path);
        final s = await file.readAsString();
        contents.add(s);
      } catch (e) {
        // ignore single-file errors and continue
        continue;
      }
    }
    return contents;
  }
}
