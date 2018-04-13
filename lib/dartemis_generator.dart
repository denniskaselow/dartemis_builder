import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
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
    final mapper = _getValues(objectValue, 'mapper');
    final systems = _getValues(objectValue, 'systems');
    final managers = _getValues(objectValue, 'manager');
    final allOfAspects = _getValues(objectValue, 'allOf');
    final oneOfAspects = _getValues(objectValue, 'oneOf');
    final excludedAspects = _getValues(objectValue, 'exclude');
    final components = new Set.from(mapper)
      ..addAll(allOfAspects)
      ..addAll(oneOfAspects);
    var mapperDeclarations = '';
    var systemDeclarations = '';
    var managerDeclarations = '';
    var mapperInitializations = '';
    var systemInitializations = '';
    var managerInitializations = '';
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
    if (managers.isNotEmpty) {
      managerDeclarations = managers
          .map((manager) => '  $manager ${toVariableName(manager)};')
          .join('\n');
      managerInitializations = managers
          .map((manager) =>
              '    ${toVariableName(manager)} = world.getManager($manager);')
          .join('\n');
    }

    StringBuffer result =
        new StringBuffer('class _\$$className extends $baseClassName {');
    if (needsDeclarations(components, systems, managers)) {
      result.writeln('');
      if (components.isNotEmpty) {
        result.writeln(mapperDeclarations);
      }
      if (systems.isNotEmpty) {
        result.writeln(systemDeclarations);
      }
      if (managers.isNotEmpty) {
        result.writeln(managerDeclarations);
      }
    }

    if (needsConstructor(allOfAspects, oneOfAspects, excludedAspects)) {
      if (!needsDeclarations(components, systems, managers)) {
        result.writeln();
      }
      result.write('  _\$$className() : super(new Aspect.empty()');
      if (allOfAspects.isNotEmpty) {
        result.write('..allOf([${allOfAspects.join(', ')}])');
      }
      if (oneOfAspects.isNotEmpty) {
        result.write('..oneOf([${oneOfAspects.join(', ')}])');
      }
      if (excludedAspects.isNotEmpty) {
        result.write('..exclude([${excludedAspects.join(', ')}])');
      }
      result.writeln(');');
    }

    if (needsInitializations(components, systems, managers)) {
      result.writeln('  @override');
      result.writeln('  void initialize() {');
      result.writeln('    super.initialize();');
      if (components.isNotEmpty) {
        result.writeln(mapperInitializations);
      }
      if (systems.isNotEmpty) {
        result.writeln(systemInitializations);
      }
      if (managers.isNotEmpty) {
        result.writeln(managerInitializations);
      }
      result.writeln('  }');
    }

    result.writeln('}');

    return result.toString();
  }

  bool needsConstructor(Iterable<String> allOfAspects,
      Iterable<String> oneOfAspects, Iterable<String> excludedAspects) {
    return allOfAspects.isNotEmpty ||
        oneOfAspects.isNotEmpty ||
        excludedAspects.isNotEmpty;
  }

  bool needsDeclarations(Set components, Iterable<String> systems,
          Iterable<String> managers) =>
      components.isNotEmpty || systems.isNotEmpty || managers.isNotEmpty;
  bool needsInitializations(Set components, Iterable<String> systems,
          Iterable<String> managers) =>
      components.isNotEmpty || systems.isNotEmpty || managers.isNotEmpty;

  Iterable<String> _getValues(DartObject objectValue, String fieldName) =>
      objectValue.getField(fieldName).toListValue().map(nameOfDartObject);

  String nameOfDartObject(dartObject) => dartObject.toTypeValue().name;

  String _toMapperName(String typeName) => toVariableName(typeName) + 'Mapper';

  String toVariableName(String typeName) =>
      typeName.substring(0, 1).toLowerCase() + typeName.substring(1);
}
