import 'package:build/build.dart';
import 'package:dartemis/dartemis.dart';
import 'package:source_gen/source_gen.dart';

import 'system_generator.dart';

/// Returns the builder that creates the .g.dart files containing the setup for
/// systems annotated with [Generate].
Builder systemBuilder(_) =>
    SharedPartBuilder([const SystemGenerator()], 'dartemis_builder');
