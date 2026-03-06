class SentimentResult {
  final String text;
  final String sentiment;  // positive / neutral / negative
  final bool toxic;
  final double score;      // -1 to +1
  final double confidence; // 0.0 - 1.0

  SentimentResult({
    required this.text,
    required this.sentiment,
    required this.toxic,
    required this.score,
    required this.confidence,
  });

  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    final parsed = double.tryParse(v.toString());
    return parsed ?? fallback;
  }

  /// Build from API JSON:
  /// { "text": "...", "sentiment": "positive", "toxic": true, "confidence": 0.92 }
  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    final text = (json['text'] ?? '').toString();
    final sentiment = (json['sentiment'] ?? 'neutral').toString().toLowerCase();
    final toxic = json['toxic'] == true || json['toxic'].toString().toLowerCase() == 'true';
    final confidence = _toDouble(json['confidence'], 0.0);

    double score;
    if (sentiment == 'positive') score = 1.0;
    else if (sentiment == 'negative') score = -1.0;
    else score = 0.0;

    // If toxic is true, ensure score is negative
    if (toxic) score = -1.0;

    return SentimentResult(
      text: text,
      sentiment: sentiment,
      toxic: toxic,
      score: score,
      confidence: confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sentiment': sentiment,
      'toxic': toxic,
      'score': score,
      'confidence': confidence,
    };
  }
}
