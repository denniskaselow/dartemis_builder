import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dartemis/dartemis.dart';

class DartemisGenerator extends GeneratorForAnnotation<Generate> {
  const DartemisGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(covariant ClassElement element,
      ConstantReader annotation, BuildStep buildStep) {
    final className = element.name;
    var objectValue = annotation.objectValue;
    final baseClassName = objectValue.getField('base').toTypeValue().name;
    final components = objectValue
        .getField('mapper')
        .toListValue()
        .map((dartObject) => dartObject.toTypeValue().name);
    var mapperDeclarations = '';
    var mapperInitializations = '';
    if (components != null) {
      mapperDeclarations = components
          .map((component) =>
              '  Mapper<$component> ${_toMapperName(component)};')
          .join('\n');
      mapperInitializations = components
          .map((component) =>
              '    ${_toMapperName(component)} = new Mapper<$component>($component, world);')
          .join('\n');
    }

    StringBuffer result =
        new StringBuffer('class _\$$className extends $baseClassName {');
    if (mapperDeclarations.isNotEmpty) {
      result.writeln('');
      result.writeln(mapperDeclarations);
    }

    if (mapperDeclarations.isNotEmpty) {
      result.writeln('  @override');
      result.writeln('  void initialize() {');
      result.writeln('    super.initialize();');
      result.writeln(mapperInitializations);
      result.writeln('  }');
    }

    result.writeln('}');

    return result.toString();
  }

  String _toMapperName(String component) =>
      component.substring(0, 1).toLowerCase() +
      component.substring(1) +
      'Mapper';
}
