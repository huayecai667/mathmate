import 'package:mathmate/visualization/safe_json_parser.dart';

class Viewport {
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  const Viewport({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  factory Viewport.fromJson(
    Map<String, dynamic> json, {
    required SafeJsonParser parser,
  }) {
    return Viewport(
      xMin: parser.safeToDouble(json['xMin'], -5),
      xMax: parser.safeToDouble(json['xMax'], 5),
      yMin: parser.safeToDouble(json['yMin'], -5),
      yMax: parser.safeToDouble(json['yMax'], 5),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'xMin': xMin,
      'xMax': xMax,
      'yMin': yMin,
      'yMax': yMax,
    };
  }
}

class GeometryElement {
  final String id;
  final String type;
  final Map<String, dynamic> raw;

  const GeometryElement({
    required this.id,
    required this.type,
    required this.raw,
  });

  factory GeometryElement.fromJson(
    Map<String, dynamic> json, {
    required SafeJsonParser parser,
  }) {
    final Map<String, dynamic> raw = parser.safeMap(json);
    final String type = parser.safeString(raw['type'], 'unknown');
    final String id = parser.safeString(raw['id'], 'unknown');

    _normalizeByType(raw, type, parser);

    return GeometryElement(
      id: id,
      type: type,
      raw: raw,
    );
  }

  static void _normalizeByType(
    Map<String, dynamic> raw,
    String type,
    SafeJsonParser parser,
  ) {
    if (raw.containsKey('offset')) {
      raw['offset'] = parser.safePoint(raw['offset']);
    }

    if (type == 'point') {
      raw['pos'] = parser.safePoint(raw['pos']);
      raw['label'] = parser.safeString(raw['label'], raw['id']?.toString() ?? '');
      return;
    }

    if (type == 'line') {
      raw['p1'] = parser.safeString(raw['p1']);
      raw['p2'] = parser.safeString(raw['p2']);
      return;
    }

    if (type == 'circle') {
      raw['center'] = parser.safePoint(raw['center']);
      raw['radius'] = parser.safeToDouble(raw['radius'], 1.0);
      return;
    }

    if (type == 'dynamic_point') {
      raw['targetId'] = parser.safeString(raw['targetId']);
      raw['initialT'] = parser.safeToDouble(raw['initialT'], 0.25);
      if (raw.containsKey('pos')) {
        raw['pos'] = parser.safePoint(raw['pos']);
      }
      raw['label'] = parser.safeString(raw['label'], raw['id']?.toString() ?? '');
    }
  }

  Map<String, dynamic> toJson() => raw;
}

class GeometryScene {
  final Viewport viewport;
  final List<GeometryElement> elements;

  const GeometryScene({required this.viewport, required this.elements});

  factory GeometryScene.fromJson(
    Map<String, dynamic> json, {
    required SafeJsonParser parser,
  }) {
    final Map<String, dynamic> safeJson = parser.safeMap(json);
    final List<dynamic> rawElements = parser.safeList(safeJson['elements']);
    return GeometryScene(
      viewport: Viewport.fromJson(
        parser.safeMap(safeJson['viewport']),
        parser: parser,
      ),
      elements: rawElements
          .map(
            (dynamic item) => GeometryElement.fromJson(
              parser.safeMap(item),
              parser: parser,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'viewport': viewport.toJson(),
      'elements': elements.map((GeometryElement e) => e.toJson()).toList(),
    };
  }
}
