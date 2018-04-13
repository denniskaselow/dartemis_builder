import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dartemis_builder/dartemis_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:build_test/build_test.dart';

void main() {
  group('', () {
    Resolver resolver;

    setUp(() async {
      resolver = new ResolverMock();
      final assetId = new AssetId.resolve('package:dartemis/dartemis.dart');
      final dartemisLibrary = resolveAsset(
          assetId, (resolver) => resolver.findLibraryByName('dartemis'));
      when(resolver.findLibraryByName('dartemis'))
          .thenAnswer((_) => dartemisLibrary);
    });

    group('generator', () {
      DartemisGenerator generator;
      BuildStep buildStep;

      setUp(() async {
        generator = const DartemisGenerator();
        buildStep = new BuildStepMock();

        when(buildStep.resolver).thenReturn(resolver);
      });

      test('should extend base class', () async {
        var result = await generate(
            systemExtendingVoidEntitySystem, generator, buildStep);

        expect(result, equals(systemExtendingVoidEntitySystemResult));
      });

      test('should create mappers', () async {
        var result = await generate(systemWithMapper, generator, buildStep);

        expect(result, equals(systemWithMapperResult));
      });
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

class ResolverMock extends Mock implements Resolver {}

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
