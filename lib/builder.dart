import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'system_generator.dart';

Builder systemBuilder(_) =>
    SharedPartBuilder([const SystemGenerator()], 'dartemis_builder');
