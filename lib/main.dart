/// 전자출결 — 앱 진입점. shared_preferences 로드 후 단일 스토어를 Provider 로 주입.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/persistence.dart';
import 'core/store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  final persistence = await Persistence.create();
  runApp(EattApp(store: AppStore(persistence)));
}

class EattApp extends StatelessWidget {
  final AppStore store;
  const EattApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStore>.value(
      value: store,
      child: MaterialApp(
        title: '전자출결',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AppRoot(),
      ),
    );
  }
}
