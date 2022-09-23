import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dartemis/dartemis.dart';
import 'package:source_gen/source_gen.dart';

/// Returns the builder that creates the .g.dart containing the setup for
/// systems.
class SystemGenerator extends GeneratorForAnnotation<Generate> {
  /// Default and only constructor.
  const SystemGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
    covariant ClassElement element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final className = element.name;
    final classConstructor = element.unnamedConstructor!;
    final combineAspects = classConstructor.parameters.any(_isAspectParameter);
    final objectValue = annotation.objectValue;
    final baseClassType = objectValue.getField('base')!.toTypeValue()!;
    final baseClassName = baseClassType.element2!.name;
    final baseClassTypeParameters =
        (baseClassType.element2! as ClassElement).typeParameters;
    final mapper = _getValues(objectValue, 'mapper');
    final systems = _getValues(objectValue, 'systems');
    final managers = _getValues(objectValue, 'manager');
    final allOfAspects = _getValues(objectValue, 'allOf');
    final oneOfAspects = _getValues(objectValue, 'oneOf');
    final excludedAspects = _getValues(objectValue, 'exclude');
    final baseClassConstructor =
        (annotation.read('base').typeValue.element2! as ClassElement)
            .unnamedConstructor!;
    final hasGeneratedAspects = allOfAspects.isNotEmpty ||
        oneOfAspects.isNotEmpty ||
        excludedAspects.isNotEmpty;
    final useSuperParameters = !hasGeneratedAspects;
    final constructorParameter = baseClassConstructor.parameters
        .where(
          (parameterElement) =>
              !_isAspectParameter(parameterElement) ||
              combineAspects ||
              useSuperParameters,
        )
        .map(
          (parameterElement) => useSuperParameters
              ? 'super.${parameterElement.name}'
              : '''${parameterElement.type.getDisplayString(withNullability: false)} ${parameterElement.name}''',
        )
        .join(', ');
    final superCallParameter = useSuperParameters
        ? ''
        : baseClassConstructor.parameters
            .map(
              (parameterElement) => _isAspectParameter(parameterElement)
                  ? _createAspectParameter(
                      allOfAspects,
                      oneOfAspects,
                      excludedAspects,
                      combineAspects,
                    )
                  : parameterElement.name,
            )
            .join(', ');
    final components = {...allOfAspects, ...mapper};
    final optionalComponents = {...oneOfAspects};
    final mapperDeclarations = components
        .map(
          (component) =>
              '  late final Mapper<$component> ${_toMapperName(component)};',
        )
        .join('\n');
    final optionalMapperDeclarations = optionalComponents
        .map(
          (component) =>
              '''  late final OptionalMapper<$component> ${_toMapperName(component)};''',
        )
        .join('\n');
    final systemDeclarations = systems
        .map((system) => '  late final $system ${_toVariableName(system)};')
        .join('\n');
    final managerDeclarations = managers
        .map((manager) => '  late final $manager ${_toVariableName(manager)};')
        .join('\n');
    final mapperInitializations = components
        .map(
          (component) =>
              '    ${_toMapperName(component)} = Mapper<$component>(world);',
        )
        .join('\n');
    final optionalMapperInitializations = optionalComponents
        .map(
          (component) =>
              '''    ${_toMapperName(component)} = OptionalMapper<$component>(world);''',
        )
        .join('\n');
    final systemInitializations = systems
        .map(
          (system) =>
              '    ${_toVariableName(system)} = world.getSystem<$system>();',
        )
        .join('\n');
    final managerInitializations = managers
        .map(
          (manager) =>
              '    ${_toVariableName(manager)} = world.getManager<$manager>();',
        )
        .join('\n');
    final result = baseClassTypeParameters.isEmpty
        ? StringBuffer('abstract class _\$$className extends $baseClassName {')
        : StringBuffer(
            '''abstract class _\$$className<${_baseClassBoundedTypeParameters(baseClassTypeParameters)}> extends $baseClassName<${_baseClassUnboundedTypeParameters(baseClassTypeParameters)}> {''',
          );
    final hasFields =
        _declaresFields(components, optionalComponents, systems, managers);
    if (hasFields) {
      result.writeln();
      if (components.isNotEmpty) {
        result.writeln(mapperDeclarations);
      }
      if (optionalComponents.isNotEmpty) {
        result.writeln(optionalMapperDeclarations);
      }
      if (systems.isNotEmpty) {
        result.writeln(systemDeclarations);
      }
      if (managers.isNotEmpty) {
        result.writeln(managerDeclarations);
      }
    }
    if (constructorParameter.isNotEmpty || superCallParameter.isNotEmpty) {
      if (!hasFields) {
        result.writeln();
      }
      result.write('  _\$$className($constructorParameter)');
      if (!useSuperParameters) {
        result.write(' : super($superCallParameter)');
      }
      result.writeln(';');
    }

    if (hasFields) {
      result
        ..writeln('  @override')
        ..writeln('  void initialize() {')
        ..writeln('    super.initialize();');
      if (components.isNotEmpty) {
        result.writeln(mapperInitializations);
      }
      if (optionalComponents.isNotEmpty) {
        result.writeln(optionalMapperInitializations);
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

  bool _isAspectParameter(ParameterElement parameterElement) =>
      parameterElement.type.getDisplayString(withNullability: false) ==
          'Aspect' ||
      parameterElement.isSuperFormal && parameterElement.name == 'aspect';

  String _baseClassBoundedTypeParameters(
    List<TypeParameterElement> baseClassTypeParameters,
  ) =>
      baseClassTypeParameters
          .map(
            (param) =>
                '''${param.name} extends ${param.bound!.getDisplayString(withNullability: false)}''',
          )
          .join(', ');

  String _baseClassUnboundedTypeParameters(
    List<TypeParameterElement> baseClassTypeParameters,
  ) =>
      baseClassTypeParameters.map((param) => param.name).join(', ');

  String _createAspectParameter(
    Iterable<String> allOfAspects,
    Iterable<String> oneOfAspects,
    Iterable<String> excludedAspects,
    bool combineAspects,
  ) {
    final result = StringBuffer(combineAspects ? 'aspect' : 'Aspect.empty()');
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

  bool _declaresFields(
    Set components,
    Set optionalComponents,
    Iterable<String> systems,
    Iterable<String> managers,
  ) =>
      components.isNotEmpty ||
      optionalComponents.isNotEmpty ||
      systems.isNotEmpty ||
      managers.isNotEmpty;

  Iterable<String> _getValues(DartObject objectValue, String fieldName) =>
      objectValue.getField(fieldName)!.toListValue()!.map(_nameOfDartObject);

  String _nameOfDartObject(DartObject dartObject) =>
      dartObject.toTypeValue()!.getDisplayString(withNullability: false);

  String _toMapperName(String typeName) => '${_toVariableName(typeName)}Mapper';

  String _toVariableName(String typeName) =>
      typeName.substring(0, 1).toLowerCase() + typeName.substring(1);
}
