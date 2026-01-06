import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/financial_report_model.dart';

class ReportExporter {
  // Brand colors
  static const _primaryColor = PdfColor.fromInt(0xFFFF9800); // Orange
  static const _secondaryColor = PdfColor.fromInt(0xFFF57C00); // Dark Orange
  static const _successColor = PdfColor.fromInt(0xFF4CAF50); // Green
  static const _warningColor = PdfColor.fromInt(0xFFFFC107); // Amber
  static const _dangerColor = PdfColor.fromInt(0xFFF44336); // Red
  static const _textColor = PdfColor.fromInt(0xFF212121);
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const _mediumGray = PdfColor.fromInt(0xFF9E9E9E);

  static final _currencyFormat = NumberFormat.currency(symbol: 'K ', decimalDigits: 2);
  static final _dateFormat = DateFormat('MMMM d, yyyy');

  static Future<void> exportFinancialReport(
    FinancialReportModel report, {
    String? groupName,
  }) async {
    final doc = pw.Document(
      title: 'Financial Report - ${groupName ?? report.groupId}',
      author: 'E-Village Banking',
      subject: 'Financial Report for ${_dateFormat.format(report.reportDate)}',
    );

    // Cover Page
    doc.addPage(_buildCoverPage(report, groupName));

    // Executive Summary Page
    doc.addPage(_buildExecutiveSummaryPage(report));

    // Financial Details Page
    doc.addPage(_buildFinancialDetailsPage(report));

    // Loan Portfolio Page
    doc.addPage(_buildLoanPortfolioPage(report));

    // Contributors Page
    doc.addPage(_buildContributorsPage(report));

    // Trends Page (if data available)
    if (report.contributionTrends.isNotEmpty) {
      doc.addPage(_buildTrendsPage(report));
    }

    final bytes = await doc.save();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Financial_Report_${_dateFormat.format(report.reportDate).replaceAll(' ', '_').replaceAll(',', '')}',
    );
  }

  static pw.Page _buildCoverPage(FinancialReportModel report, String? groupName) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            begin: pw.Alignment.topCenter,
            end: pw.Alignment.bottomCenter,
            colors: [_primaryColor, _secondaryColor],
          ),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Column(
                  children: [
                    pw.Icon(
                      pw.IconData(0xe84f), // account_balance icon code
                      size: 64,
                      color: _primaryColor,
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'E-VILLAGE BANKING',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 48),
              pw.Text(
                'FINANCIAL REPORT',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 4,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white.shade(0.9),
                  borderRadius: pw.BorderRadius.circular(24),
                ),
                child: pw.Text(
                  groupName ?? 'Village Banking Group',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 48),
              pw.Text(
                _dateFormat.format(report.reportDate),
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 80),
              pw.Text(
                'Confidential - For Internal Use Only',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white.shade(0.7),
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static pw.Page _buildExecutiveSummaryPage(FinancialReportModel report) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Executive Summary'),
          pw.SizedBox(height: 24),
          
          // Key Metrics Row
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricCard(
                  'Total Contributions',
                  _currencyFormat.format(report.totalContributions),
                  _successColor,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildMetricCard(
                  'Cash Balance',
                  _currencyFormat.format(report.cashBalance),
                  _primaryColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricCard(
                  'Outstanding Loans',
                  _currencyFormat.format(report.outstandingLoans),
                  _warningColor,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildMetricCard(
                  'Net Income',
                  _currencyFormat.format(report.netIncome),
                  report.netIncome >= 0 ? _successColor : _dangerColor,
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 32),
          
          // Financial Health Section
          _buildSectionTitle('Financial Health Overview'),
          pw.SizedBox(height: 16),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _buildHealthIndicator(
                  'Repayment Rate',
                  report.loanPortfolio.repaymentRate,
                  _getHealthColor(report.loanPortfolio.repaymentRate),
                ),
                pw.SizedBox(height: 12),
                _buildHealthIndicator(
                  'Loan Utilization',
                  report.totalContributions > 0
                      ? report.outstandingLoans / report.totalContributions
                      : 0,
                  _getUtilizationColor(
                    report.totalContributions > 0
                        ? report.outstandingLoans / report.totalContributions
                        : 0,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildHealthIndicator(
                  'Default Rate',
                  report.loanPortfolio.totalLoans > 0
                      ? report.loanPortfolio.defaultedLoans / report.loanPortfolio.totalLoans
                      : 0,
                  _getDefaultRateColor(
                    report.loanPortfolio.totalLoans > 0
                        ? report.loanPortfolio.defaultedLoans / report.loanPortfolio.totalLoans
                        : 0,
                  ),
                ),
              ],
            ),
          ),
          
          pw.Spacer(),
          _buildPageFooter(context),
        ],
      ),
    );
  }

  static pw.Page _buildFinancialDetailsPage(FinancialReportModel report) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Financial Details'),
          pw.SizedBox(height: 24),
          
          // Income Statement
          _buildSectionTitle('Income Statement'),
          pw.SizedBox(height: 12),
          
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _mediumGray, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _buildTableRow('Total Contributions', report.totalContributions, isHeader: true),
                _buildTableRow('Loan Repayments', report.totalRepayments),
                _buildTableDivider(),
                _buildTableRow(
                  'Total Income',
                  report.totalContributions + report.totalRepayments,
                  isBold: true,
                  color: _successColor,
                ),
                pw.SizedBox(height: 8),
                _buildTableRow('Loans Disbursed', report.totalLoans, isNegative: true),
                _buildTableRow('Operating Expenses', report.totalExpenses, isNegative: true),
                _buildTableDivider(),
                _buildTableRow(
                  'Net Income',
                  report.netIncome,
                  isBold: true,
                  color: report.netIncome >= 0 ? _successColor : _dangerColor,
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 32),
          
          // Balance Sheet Summary
          _buildSectionTitle('Balance Sheet Summary'),
          pw.SizedBox(height: 12),
          
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: _lightGray,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ASSETS',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _successColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildBalanceItem('Cash Balance', report.cashBalance),
                      _buildBalanceItem('Outstanding Loans', report.outstandingLoans),
                      pw.Divider(color: _mediumGray),
                      _buildBalanceItem(
                        'Total Assets',
                        report.cashBalance + report.outstandingLoans,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: _lightGray,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LIABILITIES & EQUITY',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _warningColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildBalanceItem('Member Savings', report.totalContributions),
                      _buildBalanceItem('Retained Earnings', report.netIncome),
                      pw.Divider(color: _mediumGray),
                      _buildBalanceItem(
                        'Total L & E',
                        report.totalContributions + report.netIncome,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          pw.Spacer(),
          _buildPageFooter(context),
        ],
      ),
    );
  }

  static pw.Page _buildLoanPortfolioPage(FinancialReportModel report) {
    final portfolio = report.loanPortfolio;
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Loan Portfolio Analysis'),
          pw.SizedBox(height: 24),
          
          // Portfolio Overview
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  'Total Loans',
                  portfolio.totalLoans.toString(),
                  'All time',
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  'Active Loans',
                  portfolio.activeLoans.toString(),
                  'Currently outstanding',
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  'Avg. Loan Size',
                  _currencyFormat.format(portfolio.averageLoanSize),
                  'Per loan',
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 24),
          
          // Loan Status Distribution
          _buildSectionTitle('Loan Status Distribution'),
          pw.SizedBox(height: 16),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _mediumGray, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _buildStatusBar('Active', portfolio.activeLoans, portfolio.totalLoans, _primaryColor),
                pw.SizedBox(height: 12),
                _buildStatusBar('Completed', portfolio.completedLoans, portfolio.totalLoans, _successColor),
                pw.SizedBox(height: 12),
                _buildStatusBar('Defaulted', portfolio.defaultedLoans, portfolio.totalLoans, _dangerColor),
              ],
            ),
          ),
          
          pw.SizedBox(height: 24),
          
          // Key Performance Indicators
          _buildSectionTitle('Key Performance Indicators'),
          pw.SizedBox(height: 16),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: _buildKPIItem(
                    'Repayment Rate',
                    '${(portfolio.repaymentRate * 100).toStringAsFixed(1)}%',
                    portfolio.repaymentRate >= 0.9
                        ? 'Excellent'
                        : portfolio.repaymentRate >= 0.75
                            ? 'Good'
                            : 'Needs Improvement',
                    _getHealthColor(portfolio.repaymentRate),
                  ),
                ),
                pw.Container(
                  width: 1,
                  height: 60,
                  color: _mediumGray,
                ),
                pw.Expanded(
                  child: _buildKPIItem(
                    'Default Rate',
                    portfolio.totalLoans > 0
                        ? '${((portfolio.defaultedLoans / portfolio.totalLoans) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    portfolio.defaultedLoans == 0
                        ? 'Excellent'
                        : portfolio.defaultedLoans / portfolio.totalLoans <= 0.05
                            ? 'Acceptable'
                            : 'High Risk',
                    _getDefaultRateColor(
                      portfolio.totalLoans > 0
                          ? portfolio.defaultedLoans / portfolio.totalLoans
                          : 0,
                    ),
                  ),
                ),
                pw.Container(
                  width: 1,
                  height: 60,
                  color: _mediumGray,
                ),
                pw.Expanded(
                  child: _buildKPIItem(
                    'Portfolio at Risk',
                    _currencyFormat.format(report.outstandingLoans),
                    '${portfolio.activeLoans} active loans',
                    _warningColor,
                  ),
                ),
              ],
            ),
          ),
          
          pw.Spacer(),
          _buildPageFooter(context),
        ],
      ),
    );
  }

  static pw.Page _buildContributorsPage(FinancialReportModel report) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Top Contributors'),
          pw.SizedBox(height: 24),
          
          if (report.topContributors.isEmpty)
            pw.Center(
              child: pw.Text(
                'No contribution data available',
                style: pw.TextStyle(color: _mediumGray, fontSize: 14),
              ),
            )
          else ...[
            // Table Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                color: _primaryColor,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      '#',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Member Name',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Total Amount',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Count',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // Table Rows
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _mediumGray, width: 0.5),
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(8),
                  bottomRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Column(
                children: report.topContributors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contributor = entry.value;
                  final isEven = index % 2 == 0;
                  
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isEven ? PdfColors.white : _lightGray,
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 40,
                          child: _buildRankBadge(index + 1),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            contributor.memberName,
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            _currencyFormat.format(contributor.totalAmount),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            contributor.contributionCount.toString(),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            pw.SizedBox(height: 24),
            
            // Summary Stats
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _lightGray,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStatistic(
                    'Total Contributors',
                    report.topContributors.length.toString(),
                  ),
                  _buildSummaryStatistic(
                    'Total Contributed',
                    _currencyFormat.format(
                      report.topContributors.fold(0.0, (sum, c) => sum + c.totalAmount),
                    ),
                  ),
                  _buildSummaryStatistic(
                    'Average Contribution',
                    _currencyFormat.format(
                      report.topContributors.isNotEmpty
                          ? report.topContributors.fold(0.0, (sum, c) => sum + c.totalAmount) /
                              report.topContributors.length
                          : 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          pw.Spacer(),
          _buildPageFooter(context),
        ],
      ),
    );
  }

  static pw.Page _buildTrendsPage(FinancialReportModel report) {
    final maxAmount = report.contributionTrends.fold(
      0.0,
      (max, data) => data.amount > max ? data.amount : max,
    );
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Contribution Trends'),
          pw.SizedBox(height: 24),
          
          _buildSectionTitle('Monthly Contributions'),
          pw.SizedBox(height: 16),
          
          // Bar Chart
          pw.Container(
            height: 200,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _mediumGray, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: report.contributionTrends.map((data) {
                final heightPercent = maxAmount > 0 ? data.amount / maxAmount : 0.0;
                return pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          _currencyFormat.format(data.amount),
                          style: pw.TextStyle(fontSize: 6, color: _textColor),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          height: 140 * heightPercent,
                          decoration: pw.BoxDecoration(
                            color: _primaryColor,
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(4),
                              topRight: pw.Radius.circular(4),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          data.month.length > 3 ? data.month.substring(0, 3) : data.month,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          pw.SizedBox(height: 24),
          
          // Trend Analysis
          _buildSectionTitle('Trend Analysis'),
          pw.SizedBox(height: 16),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Highest Month:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      report.contributionTrends.isNotEmpty
                          ? '${report.contributionTrends.reduce((a, b) => a.amount > b.amount ? a : b).month} - ${_currencyFormat.format(report.contributionTrends.reduce((a, b) => a.amount > b.amount ? a : b).amount)}'
                          : 'N/A',
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Lowest Month:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      report.contributionTrends.isNotEmpty
                          ? '${report.contributionTrends.reduce((a, b) => a.amount < b.amount ? a : b).month} - ${_currencyFormat.format(report.contributionTrends.reduce((a, b) => a.amount < b.amount ? a : b).amount)}'
                          : 'N/A',
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Average Monthly:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      report.contributionTrends.isNotEmpty
                          ? _currencyFormat.format(
                              report.contributionTrends.fold(0.0, (sum, d) => sum + d.amount) /
                                  report.contributionTrends.length,
                            )
                          : 'N/A',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          pw.Spacer(),
          _buildPageFooter(context),
        ],
      ),
    );
  }

  // Helper Widgets
  static pw.Widget _buildPageHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.Text(
            'E-Village Banking',
            style: pw.TextStyle(
              fontSize: 12,
              color: _primaryColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _mediumGray, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${_dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9, color: _mediumGray),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _mediumGray),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: _textColor,
      ),
    );
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.9),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: color.shade(0.3),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color.shade(0.2),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHealthIndicator(String label, double value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 11)),
        ),
        pw.Expanded(
          flex: 3,
          child: pw.Stack(
            children: [
              pw.Container(
                height: 16,
                decoration: pw.BoxDecoration(
                  color: _mediumGray.shade(0.8),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
              ),
              pw.Container(
                height: 16,
                width: 200 * value.clamp(0, 1),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.SizedBox(
          width: 50,
          child: pw.Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableRow(
    String label,
    double amount, {
    bool isHeader = false,
    bool isNegative = false,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isHeader ? _lightGray : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold || isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? _textColor,
            ),
          ),
          pw.Text(
            isNegative ? '(${_currencyFormat.format(amount)})' : _currencyFormat.format(amount),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isNegative ? _dangerColor : (color ?? _textColor),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableDivider() {
    return pw.Container(
      height: 1,
      color: _mediumGray,
      margin: const pw.EdgeInsets.symmetric(horizontal: 16),
    );
  }

  static pw.Widget _buildBalanceItem(String label, double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _currencyFormat.format(amount),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String title, String value, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 9, color: _mediumGray),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 8, color: _mediumGray),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusBar(String label, int count, int total, PdfColor color) {
    final percent = total > 0 ? count / total : 0.0;
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 10)),
        ),
        pw.Expanded(
          child: pw.Stack(
            children: [
              pw.Container(
                height: 20,
                decoration: pw.BoxDecoration(
                  color: _lightGray,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Container(
                height: 20,
                width: 300 * percent,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.SizedBox(
          width: 60,
          child: pw.Text(
            '$count (${(percent * 100).toStringAsFixed(0)}%)',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildKPIItem(String title, String value, String status, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 9, color: _mediumGray)),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            status,
            style: pw.TextStyle(fontSize: 8, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRankBadge(int rank) {
    PdfColor bgColor;
    switch (rank) {
      case 1:
        bgColor = const PdfColor.fromInt(0xFFFFD700); // Gold
        break;
      case 2:
        bgColor = const PdfColor.fromInt(0xFFC0C0C0); // Silver
        break;
      case 3:
        bgColor = const PdfColor.fromInt(0xFFCD7F32); // Bronze
        break;
      default:
        bgColor = _lightGray;
    }
    
    return pw.Container(
      width: 24,
      height: 24,
      decoration: pw.BoxDecoration(
        color: bgColor,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Text(
          rank.toString(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: rank <= 3 ? PdfColors.white : _textColor,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryStatistic(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: _mediumGray),
        ),
      ],
    );
  }

  static PdfColor _getHealthColor(double value) {
    if (value >= 0.9) return _successColor;
    if (value >= 0.75) return _warningColor;
    return _dangerColor;
  }

  static PdfColor _getUtilizationColor(double value) {
    if (value <= 0.7) return _successColor;
    if (value <= 0.85) return _warningColor;
    return _dangerColor;
  }

  static PdfColor _getDefaultRateColor(double value) {
    if (value <= 0.02) return _successColor;
    if (value <= 0.05) return _warningColor;
    return _dangerColor;
  }

  // ==================== BALANCE SHEET EXPORT ====================

  static Future<void> exportBalanceSheet({
    required String groupName,
    required DateTime asOfDate,
    required double cashOnHand,
    required double loansReceivable,
    required double interestReceivable,
    required double totalAssets,
    required double memberSavings,
    required double pendingWithdrawals,
    required double totalLiabilities,
    required double retainedEarnings,
    required double currentPeriodProfit,
    required double totalEquity,
  }) async {
    final doc = pw.Document(
      title: 'Balance Sheet - $groupName',
      author: 'E-Village Banking',
      subject: 'Balance Sheet as of ${_dateFormat.format(asOfDate)}',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _primaryColor, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BALANCE SHEET',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        groupName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: _mediumGray,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'E-Village Banking',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'As of ${_dateFormat.format(asOfDate)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: _mediumGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Accounting Equation
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _lightGray,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'ASSETS',
                        style: pw.TextStyle(fontSize: 10, color: _mediumGray),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _currencyFormat.format(totalAssets),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _successColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    '=',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _mediumGray,
                    ),
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'LIABILITIES',
                        style: pw.TextStyle(fontSize: 10, color: _mediumGray),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _currencyFormat.format(totalLiabilities),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _warningColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    '+',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _mediumGray,
                    ),
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'EQUITY',
                        style: pw.TextStyle(fontSize: 10, color: _mediumGray),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _currencyFormat.format(totalEquity),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Assets Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: _successColor.shade(0.9),
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'ASSETS',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: _successColor.shade(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _successColor.shade(0.7)),
                          borderRadius: const pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(8),
                            bottomRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            _buildBalanceSheetLine('Cash on Hand', cashOnHand),
                            _buildBalanceSheetLine('Loans Receivable', loansReceivable),
                            _buildBalanceSheetLine('Interest Receivable', interestReceivable),
                            pw.Divider(color: _mediumGray),
                            _buildBalanceSheetLine('Total Assets', totalAssets, isBold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Liabilities
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: _warningColor.shade(0.9),
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'LIABILITIES',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: _warningColor.shade(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _warningColor.shade(0.7)),
                        ),
                        child: pw.Column(
                          children: [
                            _buildBalanceSheetLine('Member Savings', memberSavings),
                            _buildBalanceSheetLine('Pending Withdrawals', pendingWithdrawals),
                            pw.Divider(color: _mediumGray),
                            _buildBalanceSheetLine('Total Liabilities', totalLiabilities, isBold: true),
                          ],
                        ),
                      ),
                      
                      pw.SizedBox(height: 8),
                      
                      // Equity
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: _primaryColor.shade(0.9),
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'EQUITY',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: _primaryColor.shade(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _primaryColor.shade(0.7)),
                          borderRadius: const pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(8),
                            bottomRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            _buildBalanceSheetLine('Retained Earnings', retainedEarnings),
                            _buildBalanceSheetLine('Current Period Profit', currentPeriodProfit),
                            pw.Divider(color: _mediumGray),
                            _buildBalanceSheetLine('Total Equity', totalEquity, isBold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),

            // Balance Check
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: (totalAssets - totalLiabilities - totalEquity).abs() < 0.01
                    ? _successColor.shade(0.9)
                    : _dangerColor.shade(0.9),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    (totalAssets - totalLiabilities - totalEquity).abs() < 0.01
                        ? '✓ Balance Sheet Balanced'
                        : '⚠ Balance Sheet Discrepancy: ${_currencyFormat.format((totalAssets - totalLiabilities - totalEquity).abs())}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: (totalAssets - totalLiabilities - totalEquity).abs() < 0.01
                          ? _successColor.shade(0.2)
                          : _dangerColor.shade(0.2),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: _mediumGray, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${_dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 9, color: _mediumGray),
                  ),
                  pw.Text(
                    'Confidential - For Internal Use Only',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: _mediumGray,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Balance_Sheet_${_dateFormat.format(asOfDate).replaceAll(' ', '_').replaceAll(',', '')}',
    );
  }

  static pw.Widget _buildBalanceSheetLine(String label, double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _currencyFormat.format(amount),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
