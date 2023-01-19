import 'dart:io';

import 'package:intlx_generator/intlx_generator.dart' as intlx;
import 'package:yaml/yaml.dart';
import 'package:code_builder/code_builder.dart';

void main(List<String> arguments) async {
  final l10n = loadYaml(await File("l10n.yaml").readAsString());
  final arbTemplate =
      await File("${l10n['arb-dir']}/${l10n['template-arb-file']}")
          .readAsString();
  final labels = intlx.getLabelsArbContent(arbTemplate);
  final library = Library((b) {
    b.directives.add(Directive.import(
        "package:flutter_gen/gen_l10n/${l10n['output-localization-file']}"));
    b.body.addAll([
      Extension((ext) {
        ext
          ..name = "AppLocalizationsExtension"
          ..on = refer("AppLocalizations")
          ..methods.add(Method((b) => b
            ..body = Code(intlx.renderCodes(labels))
            ..name = 'intlx'
            ..requiredParameters.addAll([
              Parameter((b) => b
                ..name = 'key'
                ..type = refer("String")),
            ])
            ..optionalParameters.add(
              Parameter((b) => b
                ..name = 'args'
                ..type = refer("List<Object?>?")),
            )
            ..returns = Reference("String")));
      }),
    ]);
  });
  final emitter = DartEmitter.scoped();
  final output = library.accept(emitter);
  File('lib/intlx.dart').writeAsStringSync(output.toString(), flush: true);
}
