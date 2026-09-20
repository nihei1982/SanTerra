import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_strings.dart';
import 'locale_manager.dart';

extension AppStringsX on BuildContext {
  AppStrings get strings {
    final language = watch<LocaleManager>().language;
    return AppStrings(language);
  }

  AppStrings get readStrings {
    final language = read<LocaleManager>().language;
    return AppStrings(language);
  }
}
