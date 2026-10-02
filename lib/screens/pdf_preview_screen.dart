import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/document_model.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final DocumentModel document;
  final String language;

  const PdfPreviewScreen({
    super.key,
    required this.document,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocale.text(
            language,
            'PDF Preview',
            'PDF पूर्वावलोकन',
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppLocale.text(language, 'Share PDF', 'PDF साझा करें'),
            icon: const Icon(Icons.share_rounded),
            onPressed: () => PdfService.shareDocumentPdf(document),
          ),
          IconButton(
            tooltip: AppLocale.text(language, 'Print', 'प्रिंट करें'),
            icon: const Icon(Icons.print_rounded),
            onPressed: () => PdfService.printDocumentPdf(document),
          ),
        ],
      ),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (format) => PdfService.generateDocumentPdf(document),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: '${document.title.replaceAll(RegExp(r'[^\w\s]+'), '_')}.pdf',
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.save_alt_rounded),
            onPressed: (context, build, pageFormat) async {
              await StorageService.saveDocument(document);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocale.text(
                        language,
                        'Document saved to your library ✓',
                        'दस्तावेज़ आपकी लाइब्रेरी में सहेजा गया ✓',
                      ),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
