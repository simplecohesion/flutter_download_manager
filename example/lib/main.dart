import 'package:download_manager_example/views/root_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  runApp(ProviderScope(child: const ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'Fltuter download manager test',
      theme: ThemeData(
        colorScheme: ColorSchemes.darkZinc(),
        radius: 0.5,
      ),
      home: RootView(),
    );
  }
}
