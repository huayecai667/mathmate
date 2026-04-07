import 'dart:convert';

class ExtractedResponse {
  final String cleanFormulaText;
  final String? geometryJsonText;

  const ExtractedResponse({
    required this.cleanFormulaText,
    this.geometryJsonText,
  });
}

class ResponseExtractor {
  static final RegExp _blockPattern = RegExp(
    r'```(?:geometryjson|json)\s*([\s\S]*?)```',
    caseSensitive: false,
  );

  static ExtractedResponse split(String fullResponse) {
    final Iterable<RegExpMatch> matches = _blockPattern.allMatches(fullResponse);

    for (final RegExpMatch match in matches) {
      final String blockContent = (match.group(1) ?? '').trim();
      if (!_isGeometryJson(blockContent)) {
        continue;
      }

      final String matchedText = match.group(0) ?? '';
      final String cleaned = fullResponse.replaceFirst(matchedText, '').trim();
      return ExtractedResponse(
        cleanFormulaText: cleaned,
        geometryJsonText: blockContent,
      );
    }

    if (_isGeometryJson(fullResponse.trim())) {
      return ExtractedResponse(
        cleanFormulaText: '',
        geometryJsonText: fullResponse.trim(),
      );
    }

    return ExtractedResponse(cleanFormulaText: fullResponse.trim());
  }

  static bool _isGeometryJson(String text) {
    try {
      final dynamic decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      return decoded.containsKey('viewport') && decoded.containsKey('elements');
    } catch (_) {
      return false;
    }
  }
}
