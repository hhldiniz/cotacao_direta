import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_model.dart';
import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner.dart';

Future<ChronosBoltRunner> createPlatformChronosBoltRunner(
        Map<String, dynamic> configJson, Uint8List weights) async =>
    InlineChronosBoltRunner(ChronosBoltModel.fromBytes(configJson, weights));
