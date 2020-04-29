import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dartemis/dartemis.dart';

class SystemGenerator extends GeneratorForAnnotation<Generate> {
  const SystemGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(covariant ClassElement element,
      ConstantReader annotation, BuildStep buildStep) async {
    final className = element.name;
    final classConstructor = element.unnamedConstructor;
    final combineAspects = classConstructor.parameters.any(
        (parameterElement) => parameterElement.type.element.name == 'Aspect');
    final objectValue = annotation.objectValue;
    final baseClassType = objectValue.getField('base').toTypeValue();
    final baseClassName = baseClassType.element.name;
    final baseClassTypeParameters =
        (baseClassType.element as ClassElement).typeParameters;
    final mapper = _getValues(objectValue, 'mapper');
    final systems = _getValues(objectValue, 'systems');
    final managers = _getValues(objectValue, 'manager');
    final allOfAspects = _getValues(objectValue, 'allOf');
    final oneOfAspects = _getValues(objectValue, 'oneOf');
    final excludedAspects = _getValues(objectValue, 'exclude');
    final baseClassConstructor =
        (annotation.read('base').typeValue.element as ClassElement)
            .unnamedConstructor;
    final constructorParameter = baseClassConstructor.parameters
        .where((parameterElement) =>
            parameterElement.type.element.name != 'Aspect' || combineAspects)
        .map((parameterElement) =>
            '${parameterElement.type} ${parameterElement.name}')
        .join(', ');
    final superCallParameter = baseClassConstructor.parameters
        .map((parameterElement) =>
            parameterElement.type.element.name == 'Aspect'
                ? _createAspectParameter(
                    allOfAspects, oneOfAspects, excludedAspects, combineAspects)
                : '${parameterElement.name}')
        .join(', ');
    final components = Set()
      ..addAll(allOfAspects)
      ..addAll(oneOfAspects)
      ..addAll(mapper);
    final mapperDeclarations = components
        .map((component) => '  Mapper<$component> ${_toMapperName(component)};')
        .join('\n');
    final systemDeclarations = systems
        .map((system) => '  $system ${_toVariableName(system)};')
        .join('\n');
    final managerDeclarations = managers
        .map((manager) => '  $manager ${_toVariableName(manager)};')
        .join('\n');
    final mapperInitializations = components
        .map((component) =>
            '    ${_toMapperName(component)} = Mapper<$component>(world);')
        .join('\n');
    final systemInitializations = systems
        .map((system) =>
            '    ${_toVariableName(system)} = world.getSystem<$system>();')
        .join('\n');
    final managerInitializations = managers
        .map((manager) =>
            '    ${_toVariableName(manager)} = world.getManager<$manager>();')
        .join('\n');

    StringBuffer result = baseClassTypeParameters.isEmpty
        ? StringBuffer('abstract class _\$$className extends $baseClassName {')
        : StringBuffer(
            'abstract class _\$$className<${_baseClassBoundedTypeParameters(baseClassTypeParameters)}> extends $baseClassName<${_baseClassUnboundedTypeParameters(baseClassTypeParameters)}> {');
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

    if (constructorParameter.isNotEmpty || superCallParameter.isNotEmpty) {
      if (!needsDeclarations(components, systems, managers)) {
        result.writeln();
      }
      result.write(
          '  _\$$className($constructorParameter) : super($superCallParameter');
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

  String _baseClassBoundedTypeParameters(
          List<TypeParameterElement> baseClassTypeParameters) =>
      baseClassTypeParameters
          .map((param) => '${param.name} extends ${param.bound}')
          .join(', ');

  String _baseClassUnboundedTypeParameters(
          List<TypeParameterElement> baseClassTypeParameters) =>
      baseClassTypeParameters.map((param) => param.name).join(', ');

  String _createAspectParameter(
      Iterable<String> allOfAspects,
      Iterable<String> oneOfAspects,
      Iterable<String> excludedAspects,
      bool combineAspects) {
    StringBuffer result =
        StringBuffer(combineAspects ? 'aspect' : 'Aspect.empty()');
    if (allOfAspects.isNotEmpty) {
      result.write('..allOf([${allOfAspects.join(', ')}])');
    }
    if (oneOfAspects.isNotEmpty) {
      result.write('..oneOf([${oneOfAspects.join(', ')}])');
    }
    if (excludedAspects.isNotEmpty) {
      result.write('..exclude([${excludedAspects.join(', ')}])');
    }
    return result.toString();
  }

  bool needsDeclarations(Set components, Iterable<String> systems,
          Iterable<String> managers) =>
      components.isNotEmpty || systems.isNotEmpty || managers.isNotEmpty;
  bool needsInitializations(Set components, Iterable<String> systems,
          Iterable<String> managers) =>
      components.isNotEmpty || systems.isNotEmpty || managers.isNotEmpty;

  Iterable<String> _getValues(DartObject objectValue, String fieldName) =>
      objectValue.getField(fieldName).toListValue().map(_nameOfDartObject);

  String _nameOfDartObject(dartObject) => dartObject.toTypeValue().name;

  String _toMapperName(String typeName) => _toVariableName(typeName) + 'Mapper';

  String _toVariableName(String typeName) =>
      typeName.substring(0, 1).toLowerCase() + typeName.substring(1);
}
