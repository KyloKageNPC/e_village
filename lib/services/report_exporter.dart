import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/financial_report_model.dart';

class ReportExporter {
  static Future<void> exportFinancialReport(FinancialReportModel report) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text('Group ID: ${report.groupId}'),
            pw.Text('Report Date: ${report.reportDate.toIso8601String()}'),
            pw.SizedBox(height: 8),
            pw.Text('Total Contributions: \$${report.totalContributions.toStringAsFixed(2)}'),
            pw.Text('Total Loans: \$${report.totalLoans.toStringAsFixed(2)}'),
            pw.Text('Net Income: \$${report.netIncome.toStringAsFixed(2)}'),
            pw.SizedBox(height: 12),
            pw.Text('Top Contributors:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Column(
              children: report.topContributors.map((c) => pw.Text('${c.memberName}: \$${c.totalAmount.toStringAsFixed(2)}')).toList(),
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }
}
