import 'package:calcetinopolis/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mocks de servicios', () async {
    final save = MemorySaveService();
    expect(await save.read(0), isNull);
    await save.write(0, 'x');
    expect(await save.read(0), 'x');

    final ads = MockAdService(completes: false);
    expect(await ads.showRewarded('boost'), isFalse);
    expect(ads.shown, ['boost']);

    final iap = MockIapService();
    expect(await iap.purchase('vip'), isTrue);
    expect(await iap.purchase('vip'), isFalse);

    final analytics = MemoryAnalyticsService()..log('prestige', {'n': 1});
    expect(analytics.events.single.$1, 'prestige');

    final time = FakeTimeService(DateTime(2026, 11, 3))
      ..advance(const Duration(hours: 1));
    expect(time.now(), DateTime(2026, 11, 3, 1));
  });
}
