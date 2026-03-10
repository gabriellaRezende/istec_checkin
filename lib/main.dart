import 'package:flutter/foundation.dart';

import 'main_mobile.dart' as mobile;
import 'main_web.dart' as web;

void main() {
  if (kIsWeb) {
    web.main();
  } else {
    mobile.main();
  }
}