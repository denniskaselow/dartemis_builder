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
    final components =
        objectValue.getField('mapper').toListValue().map(nameOfDartObject);
    final systems =
        objectValue.getField('systems').toListValue().map(nameOfDartObject);
    var mapperDeclarations = '';
    var systemDeclarations = '';
    var mapperInitializations = '';
    var systemInitializations = '';
    if (components.isNotEmpty) {
      mapperDeclarations = components
          .map((component) =>
              '  Mapper<$component> ${_toMapperName(component)};')
          .join('\n');
      mapperInitializations = components
          .map((component) =>
              '    ${_toMapperName(component)} = new Mapper<$component>($component, world);')
          .join('\n');
    }
    if (systems.isNotEmpty) {
      systemDeclarations = systems
          .map((system) => '  $system ${toVariableName(system)};')
          .join('\n');
      systemInitializations = systems
          .map((system) =>
              '    ${toVariableName(system)} = world.getSystem($system);')
          .join('\n');
    }

    StringBuffer result =
        new StringBuffer('class _\$$className extends $baseClassName {');
    if (components.isNotEmpty || systems.isNotEmpty) {
      result.writeln('');
      if (components.isNotEmpty) {
        result.writeln(mapperDeclarations);
      }
      if (systems.isNotEmpty) {
        result.writeln(systemDeclarations);
      }
    }

    if (components.isNotEmpty || systems.isNotEmpty) {
      result.writeln('  @override');
      result.writeln('  void initialize() {');
      result.writeln('    super.initialize();');
      if (components.isNotEmpty) {
        result.writeln(mapperInitializations);
      }
      if (systems.isNotEmpty) {
        result.writeln(systemInitializations);
      }
      result.writeln('  }');
    }

    result.writeln('}');

    return result.toString();
  }

  String nameOfDartObject(dartObject) => dartObject.toTypeValue().name;

  String _toMapperName(String component) =>
      toVariableName(component) + 'Mapper';

  String toVariableName(String component) =>
      component.substring(0, 1).toLowerCase() + component.substring(1);
}
