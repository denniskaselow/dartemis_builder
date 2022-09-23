import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartemis_builder/system_generator.dart';
import 'package:mockito/mockito.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('system generator', () {
    late SystemGenerator generator;
    late BuildStep buildStep;

    setUp(() async {
      generator = const SystemGenerator();
      buildStep = BuildStepMock();
    });

    test('should extend base class', () async {
      final result =
          await generate(systemExtendingVoidEntitySystem, generator, buildStep);

      expect(result, equals(systemExtendingVoidEntitySystemResult));
    });

    test('should handle generics', () async {
      final result = await generate(
        systemExtendingEntitySystemWithGenerics,
        generator,
        buildStep,
      );

      expect(result, equals(systemExtendingEntitySystemWithGenericsResult));
    });

    test('should create mappers', () async {
      final result = await generate(systemWithMapper, generator, buildStep);

      expect(result, equals(systemWithMapperResult));
    });

    test('should create systems', () async {
      final result =
          await generate(systemWithOtherSystem, generator, buildStep);

      expect(result, equals(systemWithOtherSystemResult));
    });

    test('should create managers', () async {
      final result = await generate(systemWithManager, generator, buildStep);

      expect(result, equals(systemWithManagerResult));
    });

    test('should create constructor and mappers for allOf aspect', () async {
      final result =
          await generate(systemWithAllOfAspect, generator, buildStep);

      expect(result, equals(systemWithAllOfAspectResult));
    });

    test('should create constructor and mappers for oneOf aspect', () async {
      final result =
          await generate(systemWithOneOfAspect, generator, buildStep);

      expect(result, equals(systemWithOneOfAspectResult));
    });

    test('should create constructor and excluded aspects', () async {
      final result =
          await generate(systemWithExcludeAspect, generator, buildStep);

      expect(result, equals(systemWithExcludeAspectResult));
    });

    test('should create constructor with parameters of superclass', () async {
      final result = await generate(
        systemExtendingOtherSystemWithCustomConstructor,
        generator,
        buildStep,
      );

      expect(
        result,
        equals(systemExtendingOtherSystemWithCustomConstructorResult),
      );
    });

    test(
        '''should create constructor with aspect parameter if user wants to pass aspects''',
        () async {
      final result = await generate(
        systemWithConstructorAcceptingAspects,
        generator,
        buildStep,
      );

      expect(result, equals(systemWithConstructorAcceptingAspectsResult));
    });

    test(
        '''should create constructor with aspect parameter if user wants to pass aspects using super parameter''',
        () async {
      final result = await generate(
        systemWithConstructorAcceptingSuperParameterAspects,
        generator,
        buildStep,
      );

      expect(result, equals(systemWithConstructorAcceptingAspectsResult));
    });

    test(
        '''should create constructor with aspect parameter if user wants to pass aspects using super parameter''',
        () async {
      final result = await generate(
        systemAcceptingSuperParameterAspectsAndGenerateAspect,
        generator,
        buildStep,
      );

      expect(
        result,
        equals(systemAcceptingSuperParameterAspectsAndGenerateAspectResult),
      );
    });

    test('should do everything together', () async {
      final result = await generate(systemWithEverything, generator, buildStep);

      expect(result, equals(systemWithEverythingResult));
    });
  });
}

Future<String> generate(
  String source,
  SystemGenerator generator,
  BuildStep buildStep,
) async {
  final libraryElement = await resolveSource<LibraryElement>(
    source,
    (resolver) async => (await resolver.findLibraryByName(''))!,
  );

  return await generator.generate(LibraryReader(libraryElement), buildStep);
}

// ignore: subtype_of_sealed_class
class BuildStepMock extends Mock implements BuildStep {}

const systemExtendingVoidEntitySystem = r'''
import 'package:dartemis/dartemis.dart';

@Generate(VoidEntitySystem)
class SimpleSystem extends _$SimpleSystem {}''';

const systemExtendingVoidEntitySystemResult = r'''
abstract class _$SimpleSystem extends VoidEntitySystem {}''';

const systemWithMapper = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(VoidEntitySystem, mapper: const [SomeComponent])
class SystemWithMapper extends _$SystemWithMapper {}''';

const systemWithMapperResult = r'''
abstract class _$SystemWithMapper extends VoidEntitySystem {
  late final Mapper<SomeComponent> someComponentMapper;
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = Mapper<SomeComponent>(world);
  }
}''';

const systemWithOtherSystem = r'''
import 'package:dartemis/dartemis.dart';

class OtherSystem extends VoidEntitySystem {}

@Generate(VoidEntitySystem, systems: const [OtherSystem])
class SystemWithOtherSystem extends _$SystemWithOtherSystem {}''';

const systemWithOtherSystemResult = r'''
abstract class _$SystemWithOtherSystem extends VoidEntitySystem {
  late final OtherSystem otherSystem;
  @override
  void initialize() {
    super.initialize();
    otherSystem = world.getSystem<OtherSystem>();
  }
}''';

const systemWithManager = r'''
import 'package:dartemis/dartemis.dart';

class SomeManager extends Manager {}

@Generate(VoidEntitySystem, manager: const [SomeManager])
class SystemWithManager extends _$SystemWithManager {}''';

const systemWithManagerResult = r'''
abstract class _$SystemWithManager extends VoidEntitySystem {
  late final SomeManager someManager;
  @override
  void initialize() {
    super.initialize();
    someManager = world.getManager<SomeManager>();
  }
}''';

const systemWithAllOfAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, allOf: const [SomeComponent])
class SomeSystem extends _$SomeSystem { {}''';

const systemWithAllOfAspectResult = r'''
abstract class _$SomeSystem extends EntitySystem {
  late final Mapper<SomeComponent> someComponentMapper;
  _$SomeSystem() : super(Aspect.empty()..allOf([SomeComponent]));
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = Mapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<int> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(int entity, SomeComponent someComponent);
}''';

const systemWithOneOfAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, oneOf: const [SomeComponent])
class SomeSystem extends _$SomeSystem { {}''';

const systemWithOneOfAspectResult = r'''
abstract class _$SomeSystem extends EntitySystem {
  late final OptionalMapper<SomeComponent> someComponentMapper;
  _$SomeSystem() : super(Aspect.empty()..oneOf([SomeComponent]));
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = OptionalMapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<int> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(int entity, SomeComponent? someComponent);
}''';

const systemWithExcludeAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, exclude: const [SomeComponent])
class SomeSystem extends _$SomeSystem { {}''';

const systemWithExcludeAspectResult = r'''
abstract class _$SomeSystem extends EntityProcessingSystem {
  _$SomeSystem() : super(Aspect.empty()..exclude([SomeComponent]));
}''';

const systemExtendingOtherSystemWithCustomConstructor = r'''
import 'package:dartemis/dartemis.dart';

class SomeOtherSystem extends VoidEntitySystem {
  String someField;
  SomeOtherSystem(this.someField);
}

@Generate(SomeOtherSystem)
class SomeSystem extends _$SomeSystem {}''';

const systemExtendingOtherSystemWithCustomConstructorResult = r'''
abstract class _$SomeSystem extends SomeOtherSystem {
  _$SomeSystem(super.someField);
}''';

const systemWithConstructorAcceptingAspects = r'''
import 'package:dartemis/dartemis.dart';

@Generate(EntityProcessingSystem)
class SomeSystem extends _$SomeSystem {
  SomeSystem(Aspect aspect) : super(aspect);
}''';

const systemWithConstructorAcceptingSuperParameterAspects = r'''
import 'package:dartemis/dartemis.dart';

@Generate(EntityProcessingSystem)
class SomeSystem extends _$SomeSystem {
  SomeSystem(super.aspect);
}''';

const systemWithConstructorAcceptingAspectsResult = r'''
abstract class _$SomeSystem extends EntityProcessingSystem {
  _$SomeSystem(super.aspect);
}''';

const systemAcceptingSuperParameterAspectsAndGenerateAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, allOf: [SomeComponent])
class SomeSystem extends _$SomeSystem {
  SomeSystem(super.aspect);
}''';

const systemAcceptingSuperParameterAspectsAndGenerateAspectResult = r'''
abstract class _$SomeSystem extends EntitySystem {
  late final Mapper<SomeComponent> someComponentMapper;
  _$SomeSystem(Aspect aspect) : super(aspect..allOf([SomeComponent]));
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = Mapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<int> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(int entity, SomeComponent someComponent);
}''';

const systemWithEverything = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}
class SomeOtherComponent extends Component {}
class YetAnotherComponent extends Component {}
class OneMoreComponent extends Component {}
class NotThisComponent extends Component {}

@Generate(Manager, mapper: const [SomeComponent])
class SomeManager extends _$SomeManager {}

@Generate(EntityProcessingSystem, allOf: const [SomeComponent], exclude: const [NotThisComponent])
class IntermediateSystem extends _$IntermediateSystem {
  String value;
  IntermediateSystem(this.value, Aspect aspect) : super(aspect);
}

@Generate(IntermediateSystem, 
  allOf: const [SomeOtherComponent], 
  oneOf: const [YetAnotherComponent],
  mapper: const [OneMoreComponent],
  manager: const [SomeManager])
class FinalSystem extends _$FinalSystem {}

@Generate(IntermediateSystem)
class OtherFinalSystem extends _$OtherFinalSystem {}
''';

const systemWithEverythingResult = r'''
abstract class _$SomeManager extends Manager {
  late final Mapper<SomeComponent> someComponentMapper;
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = Mapper<SomeComponent>(world);
  }
}

abstract class _$IntermediateSystem extends EntitySystem {
  late final Mapper<SomeComponent> someComponentMapper;
  _$IntermediateSystem(Aspect aspect) : super(aspect..allOf([SomeComponent])..exclude([NotThisComponent]));
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = Mapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<int> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(int entity, SomeComponent someComponent);
}

abstract class _$FinalSystem extends IntermediateSystem {
  late final Mapper<SomeOtherComponent> someOtherComponentMapper;
  late final Mapper<OneMoreComponent> oneMoreComponentMapper;
  late final OptionalMapper<YetAnotherComponent> yetAnotherComponentMapper;
  late final SomeManager someManager;
  _$FinalSystem(String value) : super(value, Aspect.empty()..allOf([SomeOtherComponent])..oneOf([YetAnotherComponent]));
  @override
  void initialize() {
    super.initialize();
    someOtherComponentMapper = Mapper<SomeOtherComponent>(world);
    oneMoreComponentMapper = Mapper<OneMoreComponent>(world);
    yetAnotherComponentMapper = OptionalMapper<YetAnotherComponent>(world);
    someManager = world.getManager<SomeManager>();
  }
}

abstract class _$OtherFinalSystem extends IntermediateSystem {
  _$OtherFinalSystem(super.value, super.aspect);
}''';

const systemExtendingEntitySystemWithGenerics = r'''
import 'package:dartemis/dartemis.dart';

abstract class SomeTypedSystem<T extends Object, S extends num> extends VoidEntitySystem {}

@Generate(SomeTypedSystem)
class SimpleSystem extends _$SimpleSystem<String, int> {}''';

const systemExtendingEntitySystemWithGenericsResult = r'''
abstract class _$SimpleSystem<T extends Object, S extends num> extends SomeTypedSystem<T, S> {}''';
