import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report.dart';
import '../models/report_comment.dart';

class PdfExportService {
  static Future<void> exportReportDossier(
    Report report, {
    List<ReportComment> comments = const [],
  }) async {
    final doc = pw.Document(
      title: 'Incident Dossier - CW-${report.id.substring(0, report.id.length >= 8 ? 8 : report.id.length).toUpperCase()}',
      author: 'Community Watch Security System',
    );

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Fetch images safely
    final evidenceImages = <pw.ImageProvider>[];
    for (final url in report.imageUrls) {
      try {
        final img = await networkImage(url);
        evidenceImages.add(img);
      } catch (_) {
        // Continue if single image fails to load
      }
    }

    final dateFormat = DateFormat('EEE, MMM d, yyyy • h:mm a');
    final shortDate = DateFormat('MMM d, yyyy h:mm a');
    final caseId = 'CW-${report.id.substring(0, report.id.length >= 8 ? 8 : report.id.length).toUpperCase()}';

    // Build PDF pages
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 1.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'COMMUNITY WATCH SECURITY NETWORK',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#123B5D'),
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'OFFICIAL INCIDENT INVESTIGATION DOSSIER',
                    style: const pw.TextStyle(
                      color: PdfColors.blueGrey600,
                      fontSize: 8,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#123B5D'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  caseId,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} • Community Watch Certified Record',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Banner Status & Category
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        report.title,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#123B5D'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Category: ${report.category} • Current Status: ${report.status.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: report.status == 'Resolved'
                              ? PdfColors.green800
                              : (report.status == 'Rejected'
                                  ? PdfColors.red800
                                  : PdfColors.orange800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Incident Metadata Table
          pw.Text(
            '1. INCIDENT SPECIFICATIONS',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#123B5D'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              _buildTableRow('Incident Occurrence', dateFormat.format(report.incidentAt.toLocal())),
              _buildTableRow('Report Recorded', dateFormat.format(report.createdAt.toLocal())),
              _buildTableRow('Reported Location', report.location),
              if (report.latitude != null && report.longitude != null)
                _buildTableRow(
                  'GPS Coordinates',
                  'Lat: ${report.latitude!.toStringAsFixed(6)}, Lng: ${report.longitude!.toStringAsFixed(6)}',
                ),
              _buildTableRow('Reporter Reference', 'Resident User ID: ${report.userId}'),
            ],
          ),
          pw.SizedBox(height: 16),

          // Narrative
          pw.Text(
            '2. INCIDENT NARRATIVE & RESIDENT STATEMENT',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#123B5D'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              report.description,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
            ),
          ),
          pw.SizedBox(height: 16),

          // Official Investigation Updates
          if (comments.isNotEmpty) ...[
            pw.Text(
              '3. INVESTIGATION LOG & OFFICIAL NOTES',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#123B5D'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.4),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeaderCell('Timestamp'),
                    _tableHeaderCell('Author'),
                    _tableHeaderCell('Note / Update'),
                  ],
                ),
                ...comments.map(
                  (c) => pw.TableRow(
                    children: [
                      _tableBodyCell(shortDate.format(c.createdAt.toLocal())),
                      _tableBodyCell(
                        c.isOfficial ? '[OFFICIAL] ${c.userName}' : c.userName,
                        bold: c.isOfficial,
                      ),
                      _tableBodyCell(c.comment),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Attached Photographic Evidence
          if (evidenceImages.isNotEmpty) ...[
            pw.Text(
              '4. PHOTOGRAPHIC EVIDENCE EXHIBITS (${evidenceImages.length} ATTACHED)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#123B5D'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: evidenceImages.asMap().entries.map((entry) {
                final idx = entry.key;
                final img = entry.value;
                return pw.Container(
                  width: 240,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        height: 140,
                        width: double.infinity,
                        child: pw.Image(img, fit: pw.BoxFit.cover),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Exhibit ${idx + 1} - Photographic Evidence',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          // Sign-off section
          pw.SizedBox(height: 8),
          pw.Text(
            '5. VERIFICATION & ADMINISTRATIVE SIGN-OFF',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#123B5D'),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      height: 36,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Reporting Resident Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(width: 32),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      height: 36,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Community Watch Officer / Lead Investigator', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final cleanId = report.id.length >= 8 ? report.id.substring(0, 8).toUpperCase() : 'CW_DOSSIER';
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'CW_Incident_$cleanId.pdf',
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
      ),
    );
  }

  static pw.Widget _tableBodyCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}
