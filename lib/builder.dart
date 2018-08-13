import 'package:build/build.dart';
import 'package:dartemis_builder/system_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder systemBuilder(_) =>
    SharedPartBuilder([SystemGenerator()], 'dartemis_builder');
