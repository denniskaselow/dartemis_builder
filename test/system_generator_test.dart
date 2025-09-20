// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dartemis_builder/builder.dart';
import 'package:test/test.dart';

final formatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);
final reader = TestReaderWriter(rootPackage: 'game');

void main() async {
  await reader.testing.loadIsolateSources();
  group('system generator', () {
    late Builder builder;
    late Function(String input, String output) testInOut;

    setUp(() async {
      builder = systemBuilder(BuilderOptions.empty);

      testInOut = (input, output) => generate(input, output, builder, reader);
    });

    test('should extend base class', () async {
      await testInOut(
        systemExtendingVoidEntitySystem,
        systemExtendingVoidEntitySystemResult,
      );
    });

    test('should handle generics', () async {
      await testInOut(
        systemExtendingEntitySystemWithGenerics,
        systemExtendingEntitySystemWithGenericsResult,
      );
    });

    test('should create mappers', () async {
      await testInOut(systemWithMapper, systemWithMapperResult);
    });

    test('should create systems', () async {
      await testInOut(systemWithOtherSystem, systemWithOtherSystemResult);
    });

    test('should create managers', () async {
      await testInOut(systemWithManager, systemWithManagerResult);
    });

    test('should create constructor and mappers for allOf aspect', () async {
      await testInOut(systemWithAllOfAspect, systemWithAllOfAspectResult);
    });

    test('should create constructor and mappers for oneOf aspect', () async {
      await testInOut(systemWithOneOfAspect, systemWithOneOfAspectResult);
    });

    test('should create constructor and excluded aspects', () async {
      await testInOut(systemWithExcludeAspect, systemWithExcludeAspectResult);
    });

    test('should create constructor with parameters of superclass', () async {
      await testInOut(
        systemExtendingOtherSystemWithCustomConstructor,
        systemExtendingOtherSystemWithCustomConstructorResult,
      );
    });

    test(
      'should create constructor with optional named parameters of superclass',
      () async {
        await testInOut(
          systemExtendingOtherSystemWithConstructorWithOptionalNamedParameter,
          systemExtendingOtherSystemWithConstructorWithOptionalNamedParameterResult,
        );
      },
    );

    test(
      'should create constructor with required named parameters of superclass',
      () async {
        await testInOut(
          systemExtendingOtherSystemWithConstructorWithRequiredNamedParameter,
          systemExtendingOtherSystemWithConstructorWithRequiredNamedParameterResult,
        );
      },
    );

    test(
      'should create constructor with optional positional parameters of superclass',
      () async {
        await testInOut(
          systemExtendingOtherSystemWithConstructorWithOptionalPositionalParameter,
          systemExtendingOtherSystemWithConstructorWithOptionalPositionalParameterResult,
        );
      },
    );

    test(
      'should create constructor with aspect parameter if user wants to pass aspects',
      () async {
        await testInOut(
          systemWithConstructorAcceptingAspects,
          systemWithConstructorAcceptingAspectsResult,
        );
      },
    );

    test(
      'should create constructor with aspect parameter if user wants to pass aspects using super parameter',
      () async {
        await testInOut(
          systemWithConstructorAcceptingSuperParameterAspects,
          systemWithConstructorAcceptingAspectsResult,
        );
      },
    );

    test(
      'should create constructor with aspect parameter if user wants to pass aspects using super parameter',
      () async {
        await testInOut(
          systemAcceptingSuperParameterAspectsAndGenerateAspect,
          systemAcceptingSuperParameterAspectsAndGenerateAspectResult,
        );
      },
    );

    test('should do everything together', () async {
      await testInOut(systemWithEverything, systemWithEverythingResult);
    });
  });
}

Future<void> generate(
  String source,
  String output,
  Builder builder,
  TestReaderWriter reader,
) async {
  final sharedBuilderHeader =
      '''
// ${'*' * 74}
// SystemGenerator
// ${'*' * 74}

''';

  final expectedOutput = formatter.format(sharedBuilderHeader + output);
  await testBuilder(
    builder,
    {'game|lib/src.dart': source},
    outputs: {'game|lib/src.dartemis_builder.g.part': expectedOutput},

    readerWriter: reader,
  );
}

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
  void initialize(World world) {
    super.initialize(world);
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
  void initialize(World world) {
    super.initialize(world);
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
  void initialize(World world) {
    super.initialize(world);
    someManager = world.getManager<SomeManager>();
  }
}''';

const systemWithAllOfAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, allOf: const [SomeComponent])
class SomeSystem extends _$SomeSystem {}''';

const systemWithAllOfAspectResult = r'''
abstract class _$SomeSystem extends EntitySystem {
  late final Mapper<SomeComponent> someComponentMapper;
  _$SomeSystem({super.group, super.passive}) : super(Aspect(allOf: [SomeComponent],));
  @override
  void initialize(World world) {
    super.initialize(world);
    someComponentMapper = Mapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<Entity> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(Entity entity, SomeComponent someComponent);
}''';

const systemWithOneOfAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, oneOf: const [SomeComponent])
class SomeSystem extends _$SomeSystem {}''';

const systemWithOneOfAspectResult = r'''
abstract class _$SomeSystem extends EntitySystem {
  late final OptionalMapper<SomeComponent> someComponentMapper;
  _$SomeSystem({super.group, super.passive}) : super(Aspect(oneOf: [SomeComponent],));
  @override
  void initialize(World world) {
    super.initialize(world);
    someComponentMapper = OptionalMapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<Entity> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(Entity entity, SomeComponent? someComponent);
}''';

const systemWithExcludeAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, exclude: const [SomeComponent])
class SomeSystem extends _$SomeSystem {}''';

const systemWithExcludeAspectResult = r'''
abstract class _$SomeSystem extends EntityProcessingSystem {
  _$SomeSystem({super.group, super.passive}) : super(Aspect(exclude: [SomeComponent],));
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

const systemExtendingOtherSystemWithConstructorWithOptionalNamedParameter = r'''
import 'package:dartemis/dartemis.dart';

class SomeOtherSystem extends VoidEntitySystem {
  String someField;
  String? someOptionalField;
  SomeOtherSystem(this.someField, {this.someOptionalField});
}

@Generate(SomeOtherSystem)
class SomeSystem extends _$SomeSystem {}''';

const systemExtendingOtherSystemWithConstructorWithOptionalNamedParameterResult =
    r'''
abstract class _$SomeSystem extends SomeOtherSystem {
  _$SomeSystem(super.someField, {super.someOptionalField});
}''';

const systemExtendingOtherSystemWithConstructorWithRequiredNamedParameter = r'''
import 'package:dartemis/dartemis.dart';

class SomeOtherSystem extends VoidEntitySystem {
  String someField;
  String someOptionalField;
  SomeOtherSystem(this.someField, {required this.someRequiredField});
}

@Generate(SomeOtherSystem)
class SomeSystem extends _$SomeSystem {}''';

const systemExtendingOtherSystemWithConstructorWithRequiredNamedParameterResult =
    r'''
abstract class _$SomeSystem extends SomeOtherSystem {
  _$SomeSystem(super.someField, {required super.someRequiredField});
}''';

const systemExtendingOtherSystemWithConstructorWithOptionalPositionalParameter =
    r'''
import 'package:dartemis/dartemis.dart';

class SomeOtherSystem extends VoidEntitySystem {
  String someField;
  String? someOptionalField;
  SomeOtherSystem(this.someField, [this.someOptionalField]);
}

@Generate(SomeOtherSystem)
class SomeSystem extends _$SomeSystem {}''';

const systemExtendingOtherSystemWithConstructorWithOptionalPositionalParameterResult =
    r'''
abstract class _$SomeSystem extends SomeOtherSystem {
  _$SomeSystem(super.someField, [super.someOptionalField]);
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
  _$SomeSystem(super.aspect, {super.group, super.passive});
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
  _$SomeSystem(Aspect aspect, {super.group, super.passive}) : super(aspect..allOf([SomeComponent]));
  @override
  void initialize(World world) {
    super.initialize(world);
    someComponentMapper = Mapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<Entity> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(Entity entity, SomeComponent someComponent);
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
  void initialize(World world) {
    super.initialize(world);
    someComponentMapper = Mapper<SomeComponent>(world);
  }
}

abstract class _$IntermediateSystem extends EntitySystem {
  late final Mapper<SomeComponent> someComponentMapper;
  _$IntermediateSystem(Aspect aspect, {super.group, super.passive}) : super(aspect..allOf([SomeComponent])..exclude([NotThisComponent]));
  @override
  void initialize(World world) {
    super.initialize(world);
    someComponentMapper = Mapper<SomeComponent>(world);
  }
  @override
  void processEntities(Iterable<Entity> entities) {
    final someComponentMapper = this.someComponentMapper;
    for (final entity in entities) {
      processEntity(entity, someComponentMapper[entity]);
    }
  }
  void processEntity(Entity entity, SomeComponent someComponent);
}

abstract class _$FinalSystem extends IntermediateSystem {
  late final Mapper<SomeOtherComponent> someOtherComponentMapper;
  late final Mapper<OneMoreComponent> oneMoreComponentMapper;
  late final OptionalMapper<YetAnotherComponent> yetAnotherComponentMapper;
  late final SomeManager someManager;
  _$FinalSystem(String value) : super(value, Aspect(allOf: [SomeOtherComponent],oneOf: [YetAnotherComponent],));
  @override
  void initialize(World world) {
    super.initialize(world);
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
