import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dartemis_builder/dartemis_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:build_test/build_test.dart';

void main() {
  group('generator', () {
    DartemisGenerator generator;
    BuildStep buildStep;

    setUp(() async {
      generator = const DartemisGenerator();
      buildStep = new BuildStepMock();
    });

    test('should extend base class', () async {
      var result =
          await generate(systemExtendingVoidEntitySystem, generator, buildStep);

      expect(result, equals(systemExtendingVoidEntitySystemResult));
    });

    test('should create mappers', () async {
      var result = await generate(systemWithMapper, generator, buildStep);

      expect(result, equals(systemWithMapperResult));
    });

    test('should create systems', () async {
      var result = await generate(systemWithOtherSystem, generator, buildStep);

      expect(result, equals(systemWithOtherSystemResult));
    });

    test('should create managers', () async {
      var result = await generate(systemWithManager, generator, buildStep);

      expect(result, equals(systemWithManagerResult));
    });

    test('should create constructor and mappers for allOf aspect', () async {
      var result = await generate(systemWithAllOfAspect, generator, buildStep);

      expect(result, equals(systemWithAllOfAspectResult));
    });

    test('should create constructor and mappers for oneOf aspect', () async {
      var result = await generate(systemWithOneOfAspect, generator, buildStep);

      expect(result, equals(systemWithOneOfAspectResult));
    });

    test('should create constructor and excluded aspects', () async {
      var result =
          await generate(systemWithExcludeAspect, generator, buildStep);

      expect(result, equals(systemWithExcludeAspectResult));
    });

    test('should create constructor with parameters of superclass', () async {
      var result = await generate(
          systemExtendingOtherSystemWithCustomConstructor,
          generator,
          buildStep);

      expect(result,
          equals(systemExtendingOtherSystemWithCustomConstructorResult));
    });
  });
}

Future<String> generate(
    String source, DartemisGenerator generator, BuildStep buildStep) async {
  final libraryElement =
      await resolveSource<LibraryElement>(source, (resolver) {
    return resolver.findLibraryByName('');
  });

  return await generator.generate(new LibraryReader(libraryElement), buildStep);
}

class BuildStepMock extends Mock implements BuildStep {}

const systemExtendingVoidEntitySystem = r'''
import 'package:dartemis/dartemis.dart';

@Generate(VoidEntitySystem)
class SimpleSystem extends _$SimpleSystem {}
''';

const systemExtendingVoidEntitySystemResult = r'''
class _$SimpleSystem extends VoidEntitySystem {}
''';

const systemWithMapper = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(VoidEntitySystem, mapper: const [SomeComponent])
class SystemWithMapper extends _$SystemWithMapper {}
''';

const systemWithMapperResult = r'''
class _$SystemWithMapper extends VoidEntitySystem {
  Mapper<SomeComponent> someComponentMapper;
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = new Mapper<SomeComponent>(SomeComponent, world);
  }
}
''';

const systemWithOtherSystem = r'''
import 'package:dartemis/dartemis.dart';

class OtherSystem extends VoidEntitySystem {}

@Generate(VoidEntitySystem, systems: const [OtherSystem])
class SystemWithOtherSystem extends _$SystemWithOtherSystem {}
''';

const systemWithOtherSystemResult = r'''
class _$SystemWithOtherSystem extends VoidEntitySystem {
  OtherSystem otherSystem;
  @override
  void initialize() {
    super.initialize();
    otherSystem = world.getSystem(OtherSystem);
  }
}
''';

const systemWithManager = r'''
import 'package:dartemis/dartemis.dart';

class SomeManager extends Manager {}

@Generate(VoidEntitySystem, manager: const [SomeManager])
class SystemWithManager extends _$SystemWithManager {}
''';

const systemWithManagerResult = r'''
class _$SystemWithManager extends VoidEntitySystem {
  SomeManager someManager;
  @override
  void initialize() {
    super.initialize();
    someManager = world.getManager(SomeManager);
  }
}
''';

const systemWithAllOfAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, allOf: const [SomeComponent])
class SomeSystem extends _$SomeSystem { {}
''';

const systemWithAllOfAspectResult = r'''
class _$SomeSystem extends EntityProcessingSystem {
  Mapper<SomeComponent> someComponentMapper;
  _$SomeSystem() : super(new Aspect.empty()..allOf([SomeComponent]));
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = new Mapper<SomeComponent>(SomeComponent, world);
  }
}
''';

const systemWithOneOfAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, oneOf: const [SomeComponent])
class SomeSystem extends _$SomeSystem { {}
''';

const systemWithOneOfAspectResult = r'''
class _$SomeSystem extends EntityProcessingSystem {
  Mapper<SomeComponent> someComponentMapper;
  _$SomeSystem() : super(new Aspect.empty()..oneOf([SomeComponent]));
  @override
  void initialize() {
    super.initialize();
    someComponentMapper = new Mapper<SomeComponent>(SomeComponent, world);
  }
}
''';

const systemWithExcludeAspect = r'''
import 'package:dartemis/dartemis.dart';

class SomeComponent extends Component {}

@Generate(EntityProcessingSystem, exclude: const [SomeComponent])
class SomeSystem extends _$SomeSystem { {}
''';

const systemWithExcludeAspectResult = r'''
class _$SomeSystem extends EntityProcessingSystem {
  _$SomeSystem() : super(new Aspect.empty()..exclude([SomeComponent]));
}
''';

const systemExtendingOtherSystemWithCustomConstructor = r'''
import 'package:dartemis/dartemis.dart';

class SomeOtherSystem extends VoidEntitySystem {
  String someField;
  SomeOtherSystem(this.someField);
}

@Generate(SomeOtherSystem)
class SomeSystem extends _$SomeSystem {}
''';

const systemExtendingOtherSystemWithCustomConstructorResult = r'''
class _$SomeSystem extends SomeOtherSystem {
  _$SomeSystem(String someField) : super(someField);
}
''';
