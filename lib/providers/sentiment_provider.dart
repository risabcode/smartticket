// lib/providers/sentiment_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../services/file_service.dart';
import '../services/sentiment_service.dart';
import '../models/sentiment_model.dart';

class SentimentProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  final SentimentService _sentimentService = SentimentService();

  // ----------------------------------------------------------------------
  // STATE
  // ----------------------------------------------------------------------
  List<SentimentResult> items = [];
  List<String> extractedComments = [];

  bool loading = false;
  String error = '';

  int positive = 0;
  int neutral = 0;
  int negative = 0;
  int toxic = 0;

  // ----------------------------------------------------------------------
  // FIX FOR DASHBOARD ERRORS
  // ----------------------------------------------------------------------

  /// Total sentiment count
  int get totalCount =>
      positive + neutral + negative + toxic;

  /// Whether *any* data exists
  bool get hasAnyData =>
      extractedComments.isNotEmpty || items.isNotEmpty;

  // ----------------------------------------------------------------------
  // CLEAR STATE
  // ----------------------------------------------------------------------
  void clearAll() {
    items = [];
    extractedComments = [];
    loading = false;
    error = '';
    positive = neutral = negative = toxic = 0;
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // SETTERS FOR RESULTS
  // ----------------------------------------------------------------------
  void setItems(List<SentimentResult> list) {
    items = list;
    _deriveSummaryFromItems();
    notifyListeners();
  }

  void addAll(List<SentimentResult> list) {
    items.addAll(list);
    _deriveSummaryFromItems();
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // MAIN FUNCTION: PICK → EXTRACT → ANALYZE
  // ----------------------------------------------------------------------
  Future<void> pickAndAnalyze() async {
    loading = true;
    error = '';
    notifyListeners();

    try {
      final fileContents = await _fileService.pickJsonFiles();

      if (fileContents.isEmpty) {
        loading = false;
        error = 'No files selected.';
        notifyListeners();
        return;
      }

      final comments = <String>[];

      // Extract comments from each JSON file
      for (final content in fileContents) {
        try {
          final jsonObj = jsonDecode(content);
          comments.addAll(_extractComments(jsonObj));
        } catch (_) {
          continue;
        }
      }

      extractedComments = comments;

      if (comments.isEmpty) {
        loading = false;
        error = 'No comments found in selected JSON files.';
        notifyListeners();
        return;
      }

      // Send to AI sentiment analyzer
      final results = await _sentimentService.analyzeComments(comments);

      setItems(results);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------------
  // SUMMARIZE SENTIMENT COUNTS
  // ----------------------------------------------------------------------
  void _deriveSummaryFromItems() {
    positive = neutral = negative = toxic = 0;

    for (final r in items) {
      final s = (r.sentiment ?? '').toLowerCase();

      if (r.toxic == true) {
        toxic++;
      } else if (s.contains('positive')) {
        positive++;
      } else if (s.contains('negative')) {
        negative++;
      } else {
        neutral++;
      }
    }
  }

  // ----------------------------------------------------------------------
  // POWERFUL COMMENT EXTRACTOR
  // Supports Facebook, Instagram & Twitter JSON structures.
  // ----------------------------------------------------------------------
  List<String> _extractComments(dynamic node) {
    final comments = <String>[];

    void walk(dynamic n) {
      if (n == null) return;

      if (n is String) return;

      if (n is Map) {
        for (final entry in n.entries) {
          final key = entry.key.toString().toLowerCase();
          final value = entry.value;

          if ((key.contains('comment') ||
                  key.contains('body') ||
                  key.contains('text')) &&
              value is String &&
              value.trim().isNotEmpty) {
            comments.add(value.trim());
          } else {
            walk(value);
          }
        }
      }

      if (n is List) {
        for (final el in n) walk(el);
      }
    }

    // Special-case detection for Facebook shapes
    if (node is Map) {
      for (final k in node.keys) {
        final lower = k.toString().toLowerCase();

        if ((lower.contains('comment') || lower.contains('comments')) &&
            node[k] is List) {
          for (final el in node[k]) {
            if (el is Map && el['data'] != null) {
              final data = el['data'];

              if (data is List) {
                for (final d in data) {
                  if (d is Map) {
                    if (d.containsKey('comment')) {
                      final c = d['comment'];

                      if (c is Map && c['comment'] is String) {
                        comments.add(c['comment']);
                      } else if (c is String) {
                        comments.add(c);
                      }
                    } else {
                      comments.addAll(_extractComments(d));
                    }
                  } else {
                    comments.addAll(_extractComments(d));
                  }
                }
              } else {
                comments.addAll(_extractComments(data));
              }
            } else {
              comments.addAll(_extractComments(el));
            }
          }
        }
      }
    }

    // Generic walk
    walk(node);

    // Deduplicate
    final unique = <String>{};
    final out = <String>[];

    for (final c in comments) {
      final t = c.trim();
      if (t.isNotEmpty && !unique.contains(t)) {
        unique.add(t);
        out.add(t);
      }
    }

    return out;
  }
}
