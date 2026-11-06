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

    final iap = MockIapService(prices: {'vip': '\$149.00 MXN'});
    await iap.load({'vip'});
    expect(iap.priceOf('vip'), '\$149.00 MXN');
    expect(iap.priceOf('otro'), isNull);
    expect(await iap.purchase('vip'), isTrue);
    expect(iap.purchases, ['vip']);
    expect(await MockIapService(succeeds: false).purchase('vip'), isFalse);
    expect(await (MockIapService()..owned.add('vip')).restore(), {'vip'});

    final analytics = MemoryAnalyticsService()..log('prestige', {'n': 1});
    expect(analytics.events.single.$1, 'prestige');

    final time = FakeTimeService(DateTime(2026, 11, 3))
      ..advance(const Duration(hours: 1));
    expect(time.now(), DateTime(2026, 11, 3, 1));
  });
}
