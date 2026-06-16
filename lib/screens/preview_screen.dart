import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';
import '../templates/resume_pdf_builder.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resumeData = context.watch<ResumeProvider>().resumeData;
    final fileName = resumeData.personalInfo.fullName.isEmpty
        ? 'resume.pdf'
        : '${resumeData.personalInfo.fullName.replaceAll(' ', '_')}.pdf';

    return Scaffold(
      appBar: AppBar(title: const Text('Preview & Export')),
      body: PdfPreview(
        build: (format) => ResumePdfBuilder.build(resumeData),
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: fileName,
      ),
    );
  }
}
