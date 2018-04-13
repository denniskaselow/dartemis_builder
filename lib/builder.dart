import 'package:build/build.dart';
import 'package:dartemis_builder/dartemis_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder dartemis = new PartBuilder([new DartemisGenerator()]);
