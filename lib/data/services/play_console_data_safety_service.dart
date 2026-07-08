import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

class PlayConsoleDataSafetyRow {
  final String questionId;
  final String? responseId;
  final String? responseValue;
  final String? answerRequirement;
  final String? humanLabel;

  const PlayConsoleDataSafetyRow({
    required this.questionId,
    this.responseId,
    this.responseValue,
    this.answerRequirement,
    this.humanLabel,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'responseId': responseId,
        'responseValue': responseValue,
        'answerRequirement': answerRequirement,
        'humanLabel': humanLabel,
      };
}

class PlayConsoleDataSafetyImportResult {
  final List<PlayConsoleDataSafetyRow> rows;
  final String sourceFileName;

  const PlayConsoleDataSafetyImportResult({
    required this.rows,
    required this.sourceFileName,
  });

  int get totalRows => rows.length;
  int get enabledRows => rows.where((row) {
        final value = row.responseValue?.toLowerCase();
        return value == 'true' || value == 'yes' || value == 'sí' || value == 'si';
      }).length;

  String toJsonString() => jsonEncode({
        'sourceFileName': sourceFileName,
        'totalRows': totalRows,
        'rows': rows.map((r) => r.toJson()).toList(),
      });
}

class PlayConsoleDataSafetyService {
  const PlayConsoleDataSafetyService();

  Future<PlayConsoleDataSafetyImportResult> parseFile(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    final table = Csv().decode(contents.replaceAll('\r', ''));

    if (table.isEmpty) {
      return PlayConsoleDataSafetyImportResult(
        rows: const [],
        sourceFileName: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : file.path,
      );
    }

    final header = table.first.map((c) => c.toString().trim()).toList();
    final index = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      index[header[i].toLowerCase()] = i;
    }

    String? cell(List<dynamic> row, List<String> keys) {
      for (final key in keys) {
        final idx = index[key.toLowerCase()];
        if (idx == null || idx >= row.length) continue;
        final value = row[idx]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final rows = <PlayConsoleDataSafetyRow>[];
    for (var i = 1; i < table.length; i++) {
      final row = table[i];
      final questionId = cell(row, ['Question ID (machine readable)', 'Question ID']);
      if (questionId == null) continue;

      rows.add(PlayConsoleDataSafetyRow(
        questionId: questionId,
        responseId: cell(row, ['Response ID (machine readable)', 'Response ID']),
        responseValue: cell(row, ['Response value']),
        answerRequirement: cell(row, ['Answer requirement']),
        humanLabel: cell(row, ['Human-friendly question label']),
      ));
    }

    return PlayConsoleDataSafetyImportResult(
      rows: rows,
      sourceFileName: file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : file.path,
    );
  }
}
