import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sentiment_model.dart';

class SentimentService {
  /// For Android emulator -> host PC
  final String baseUrl = "http://10.0.2.2:5000";

  // ----------------------------------------------------------------------
  //                        BULK ANALYZE (MAIN)
  // ----------------------------------------------------------------------
  Future<List<SentimentResult>> analyzeComments(List<String> comments) async {
    if (comments.isEmpty) return [];

    try {
      final url = Uri.parse("$baseUrl/analyze_bulk");

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"texts": comments}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = data["results"] as List<dynamic>? ?? [];

        /// SAFE MAP CONVERSION
        final list = results.map<SentimentResult>((item) {
          if (item is Map) {
            final map = item.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            );
            return SentimentResult.fromJson(map);
          } else {
            return SentimentResult(
              text: "",
              sentiment: "neutral",
              toxic: false,
              score: 0.0,
              confidence: 0.0,
            );
          }
        }).toList();

        return list;
      } else {
        print("analyzeComments failed ${resp.statusCode}: ${resp.body}");
      }
    } catch (e) {
      print("Error in analyzeComments(): $e");
    }

    // fallback: neutral for every comment
    return comments
        .map(
          (c) => SentimentResult(
            text: c,
            sentiment: "neutral",
            toxic: false,
            score: 0.0,
            confidence: 0.0,
          ),
        )
        .toList();
  }

  // ----------------------------------------------------------------------
  //                Analyze YOUTUBE COMMENTS (Map objects)
  // ----------------------------------------------------------------------
  Future<List<SentimentResult>> analyzeCommentsFromMaps(
      List<Map<String, dynamic>> comments) async {
    final texts = <String>[];

    for (var c in comments) {
      final t = (c['text'] ??
              c['textOriginal'] ??
              c['textDisplay'] ??
              "")
          .toString();

      if (t.trim().isNotEmpty) texts.add(t);
    }

    return await analyzeComments(texts);
  }

  // ----------------------------------------------------------------------
  //                   ANALYZE ONE COMMENT
  // ----------------------------------------------------------------------
  Future<SentimentResult> analyzeOne(String text) async {
    final list = await analyzeComments([text]);
    if (list.isNotEmpty) return list.first;

    return SentimentResult(
      text: text,
      sentiment: "neutral",
      toxic: false,
      score: 0.0,
      confidence: 0.0,
    );
  }
}
