import 'dart:convert';

class PlaceholderException implements Exception {
  final String message;

  PlaceholderException(this.message);

  @override
  String toString() => message;
}

class Placeholder {
  final String resourceId;
  final String name;
  final String? example;
  final String? type;
  final String? format;
  final List<OptionalParameter> optionalParameters;
  final bool? isCustomDateFormat;

  Placeholder(this.resourceId, this.name, Map<String, Object?> attributes)
      : example = _stringAttribute(resourceId, name, attributes, 'example'),
        type = _stringAttribute(resourceId, name, attributes, 'type'),
        format = _stringAttribute(resourceId, name, attributes, 'format'),
        optionalParameters = _optionalParameters(resourceId, name, attributes),
        isCustomDateFormat =
            _boolAttribute(resourceId, name, attributes, 'isCustomDateFormat');

  static String? _stringAttribute(
    String resourceId,
    String name,
    Map<String, Object?> attributes,
    String attributeName,
  ) {
    final Object? value = attributes[attributeName];
    if (value == null) {
      return null;
    }
    if (value is! String || value.isEmpty) {
      throw PlaceholderException(
          "The '$attributeName' value of the '$name' placeholder in message '$resourceId' must be a non-empty string.");
    }
    return value;
  }

  static bool? _boolAttribute(
    String resourceId,
    String name,
    Map<String, Object?> attributes,
    String attributeName,
  ) {
    final Object? value = attributes[attributeName];
    if (value == null) {
      return null;
    }
    if (value != 'true' && value != 'false') {
      throw PlaceholderException(
        "The '$attributeName' value of the '$name' placeholder in message '$resourceId' must be a string representation of a boolean value ('true', 'false').",
      );
    }
    return value == 'true';
  }

  static List<OptionalParameter> _optionalParameters(
      String resourceId, String name, Map<String, Object?> attributes) {
    final Object? value = attributes['optionalParameters'];
    if (value == null) {
      return <OptionalParameter>[];
    }

    if (value is! Map<String, dynamic>) {
      throw PlaceholderException(
          "The 'optionalParameters' value of the '$name' placeholder in message '$resourceId' is not a properly formatted Map. "
          "Ensure that it is a map with keys that are strings.");
    }
    final Map<String, Object> optionalParameterMap =
        Map<String, Object>.from(value);
    return optionalParameterMap.keys
        .map<OptionalParameter>((String parameterName) => OptionalParameter(
            parameterName, optionalParameterMap[parameterName]!))
        .toList();
  }
}

class OptionalParameter {
  const OptionalParameter(this.name, this.value);

  final String name;
  final Object value;
}

class Label {
  String name;
  String content;
  String? type;
  String? description;
  List<Placeholder>? placeholders;

  Label(this.name, this.content,
      {this.type, this.description, this.placeholders});

  @override
  String toString() {
    return 'Label(name: $name, content: $content, type: $type, description: $description, placeholders: $placeholders)';
  }
}

List<Label> getLabelsArbContent(String content) {
  var decodedContent = json.decode(content) as Map<String, dynamic>;

  var labels =
      decodedContent.keys.where((key) => !key.startsWith('@')).map((key) {
    var name = key;
    var content = decodedContent[key];

    var meta = decodedContent['@$key'] ?? {};
    var type = meta['type'];
    var description = meta['description'];
    var placeholders = meta['placeholders'] != null
        ? (meta['placeholders'] as Map<String, dynamic>)
            .keys
            .map((placeholder) => Placeholder(
                key, placeholder, meta['placeholders'][placeholder]))
            .toList()
        : null;

    return Label(name, content,
        type: type, description: description, placeholders: placeholders);
  }).toList();

  return labels;
}

String renderCodes(List<Label> labels) {
  final sb = StringBuffer();
  sb.write("switch (key) {");
  for (var fn in labels) {
    if (fn.placeholders?.isEmpty ?? true) {
      sb.write('case "${fn.name}": return ${fn.name};');
      continue;
    }
    sb.write('case "${fn.name}":');
    final paramtersLength = fn.placeholders!.length;

    for (var i = 0; i < fn.placeholders!.length; i++) {
      final placeholder = fn.placeholders!.elementAt(i);
      sb.write(
          'final p$i = args!.elementAt($i)!${placeholder.type != null ? ' as ${placeholder.type}' : ''};');
    }

    for (var i = 0; i < paramtersLength; i++) {}
    sb.write('return ${fn.name}(');
    for (var i = 0; i < paramtersLength; i++) {
      sb.write('p$i');
      if (i < paramtersLength - 1) {
        sb.write(',');
      }
    }
    sb.write(');');
  }
  sb.write("default: throw Exception('Key not found');}");
  return sb.toString();
}
