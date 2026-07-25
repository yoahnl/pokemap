import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('phase 8 budgets cover the audited reference workloads', () {
    expect(ProductCertificationBudgets.libraryGameCount, 100);
    expect(ProductCertificationBudgets.speciesCatalogCount, 2000);
    expect(
      ProductCertificationBudgets.libraryLoad,
      const Duration(seconds: 5),
    );
    expect(
      ProductCertificationBudgets.catalogExportAndInspection,
      const Duration(seconds: 30),
    );
    expect(
      ProductCertificationBudgets.opaqueProgressSilence,
      const Duration(seconds: 2),
    );
  });

  test('budget measurement reports pass or fail without hiding duration', () {
    final passed = ProductCertificationMeasurement.evaluate(
      id: 'library-100',
      elapsed: const Duration(milliseconds: 800),
      budget: const Duration(seconds: 5),
    );
    final failed = ProductCertificationMeasurement.evaluate(
      id: 'catalog-2000',
      elapsed: const Duration(seconds: 31),
      budget: const Duration(seconds: 30),
    );

    expect(passed.passed, isTrue);
    expect(passed.toJson()['elapsedMs'], 800);
    expect(failed.passed, isFalse);
    expect(failed.toJson()['budgetMs'], 30000);
  });
}
