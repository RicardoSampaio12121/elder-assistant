import 'package:careapp/app.dart';
import 'package:careapp/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on the placeholder home screen in PT-PT', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CareApp()));
    await tester.pumpAndSettle();

    expect(find.text('CareApp'), findsOneWidget);
    expect(find.text('Bem-vindo ao CareApp'), findsOneWidget);
    expect(find.text('Em breve, mais funcionalidades.'), findsOneWidget);
  });

  test('dio is configured with the API base URL', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    expect(dio.options.baseUrl, apiBaseUrl);
  });
}
