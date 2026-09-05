import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_builder.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template_repository.dart';

/// Bundled POS receipt template (aligned layout) stored in SQLite once.
class ReceiptTemplateSeed {
  ReceiptTemplateSeed({required ReceiptTemplateRepository repository})
      : _repository = repository;

  final ReceiptTemplateRepository _repository;

  static const String bundledTemplateName = 'POS Aligned (EN+AR)';

  /// Inserts the default aligned POS template if it is not already saved.
  Future<void> ensureBundledPosTemplate() async {
    final existing = await _repository.list();
    if (existing.any((t) => t.name == bundledTemplateName)) {
      return;
    }

    final markup = PosReceiptBuilder.preloadedTemplate().buildMarkupLines();
    await _repository.save(
      ReceiptTemplate(
        id: '',
        name: bundledTemplateName,
        lines: markup,
        paper: PaperSize.thermal80mm,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}
