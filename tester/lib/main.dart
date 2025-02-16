import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:tester/views/root_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(ProviderScope(child: const ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'Fltuter download manager test',
      theme: ThemeData(colorScheme: ColorSchemes.lightSlate(), radius: 0.3),
      home: RootView(),
    );
  }
}
