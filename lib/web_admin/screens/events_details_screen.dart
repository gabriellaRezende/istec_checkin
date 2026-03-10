import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';
import 'package:istec_checkin/web_admin/screens/home_screen.dart';
import 'package:istec_checkin/web_admin/screens/events_screen.dart';
import 'package:istec_checkin/web_admin/screens/requests_screen.dart';
import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<List<Map<String, dynamic>>> _checkinsFuture;

  @override
  void initState() {
    super.initState();
    _checkinsFuture = _loadCheckins();
  }

  Future<List<Map<String, dynamic>>> _loadCheckins() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('checkins')
        .select()
        .eq('event_id', widget.event['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _reload() async {
    setState(() {
      _checkinsFuture = _loadCheckins();
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String get _qrData => 'ISTEC_EVENT:${widget.event['id']}';

  double _safeRatio(int value, int total) {
    if (total <= 0) return 0;
    return value / total;
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return '-';
    final lower = status.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Future<Uint8List> _buildPdfBytes({
    required String name,
    required String address,
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
    required String status,
    required String radius,
    required int total,
    required int approved,
    required int rejected,
    required int pending,
    required List<Map<String, dynamic>> checkins,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Relatório do Evento',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Nome: $name'),
          pw.Text('Morada: $address'),
          pw.Text('Início: $startDate às $startTime'),
          pw.Text('Fim: $endDate às $endTime'),
          pw.Text('Estado: $status'),
          pw.Text('Raio permitido: $radius m'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Resumo',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total de check-ins: $total'),
          pw.Text('Aprovados: $approved'),
          pw.Text('Rejeitados: $rejected'),
          pw.Text('Pendentes: $pending'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Lista de Check-ins',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (checkins.isEmpty)
            pw.Text('Nenhum check-in encontrado para este evento.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Aluno', 'Estado', 'Leitura'],
              data: checkins.map((checkin) {
                final studentName = (checkin['student_name'] ?? 'Aluno')
                    .toString();
                final checkinStatus = _capitalizeStatus(
                  (checkin['status'] ?? '-').toString(),
                );
                final readAt = _formatDateTime(
                  (checkin['read_at'] ?? checkin['created_at'])?.toString(),
                );

                return [studentName, checkinStatus, readAt];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _exportPdf({
    required String name,
    required String address,
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
    required String status,
    required String radius,
    required int total,
    required int approved,
    required int rejected,
    required int pending,
    required List<Map<String, dynamic>> checkins,
  }) async {
    try {
      final bytes = await _buildPdfBytes(
        name: name,
        address: address,
        startDate: startDate,
        startTime: startTime,
        endDate: endDate,
        endTime: endTime,
        status: status,
        radius: radius,
        total: total,
        approved: approved,
        rejected: rejected,
        pending: pending,
        checkins: checkins,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'relatorio_evento_${widget.event['id']}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao exportar PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.event['name'] ?? 'Evento').toString();
    final address = (widget.event['adress'] ?? '-').toString();
    final startDate = _formatDate(widget.event['start_date']?.toString());
    final startTime = _formatTime(widget.event['start_time']?.toString());
    final endDate = _formatDate(widget.event['end_date']?.toString());
    final endTime = _formatTime(widget.event['end_time']?.toString());
    final status = (widget.event['status'] ?? '-').toString();
    final radius = (widget.event['radius_meters'] ?? '-').toString();
    final latitude = (widget.event['latitude'] ?? '-').toString();
    final longitude = (widget.event['longitude'] ?? '-').toString();

    return Scaffold(
      appBar: TopNavigation(
        title: 'Detalhe do Evento',
        currentSection: AdminSection.events,
        onDashboard: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        },
        onEvents: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EventsScreen()),
          );
        },
        onRequests: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RequestsScreen()),
          );
        },
        onSignOut: () async {
          await AuthService.signOutAndRedirect(context);
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _checkinsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar detalhe do evento: ${snapshot.error}',
              ),
            );
          }

          final checkins = snapshot.data ?? [];
          final total = checkins.length;
          final approved = checkins
              .where(
                (c) =>
                    (c['status'] ?? '').toString().toLowerCase() == 'approved',
              )
              .length;
          final rejected = checkins
              .where(
                (c) =>
                    (c['status'] ?? '').toString().toLowerCase() == 'rejected',
              )
              .length;
          final pending = checkins
              .where(
                (c) =>
                    (c['status'] ?? '').toString().toLowerCase() == 'pending',
              )
              .length;

          return Container(
            decoration: BrandTheme.screenBackground(),
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BrandTheme.softPanel(),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _InfoRow(label: 'Morada', value: address),
                                _InfoRow(
                                  label: 'Início',
                                  value: '$startDate às $startTime',
                                ),
                                _InfoRow(
                                  label: 'Fim',
                                  value: '$endDate às $endTime',
                                ),
                                _InfoRow(
                                  label: 'Raio permitido',
                                  value: '$radius m',
                                ),
                                _InfoRow(label: 'Latitude', value: latitude),
                                _InfoRow(label: 'Longitude', value: longitude),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Estado: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BrandTheme.softPanel(),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  'QR Code',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: BrandTheme.mist,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: QrImageView(
                                    data: _qrData,
                                    version: QrVersions.auto,
                                    size: 220,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Este QR identifica o evento para o check-in no app mobile.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Resumo do Evento',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _SummaryCard(
                        title: 'Total',
                        value: total.toString(),
                        color: Colors.blue,
                      ),
                      _SummaryCard(
                        title: 'Aprovados',
                        value: approved.toString(),
                        color: Colors.green,
                      ),
                      _SummaryCard(
                        title: 'Rejeitados',
                        value: rejected.toString(),
                        color: Colors.red,
                      ),
                      _SummaryCard(
                        title: 'Pendentes',
                        value: pending.toString(),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BrandTheme.softPanel(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gráfico de Check-ins',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ChartBarRow(
                            label: 'Aprovados',
                            value: approved,
                            total: total,
                            color: Colors.green,
                            ratio: _safeRatio(approved, total),
                          ),
                          const SizedBox(height: 12),
                          _ChartBarRow(
                            label: 'Rejeitados',
                            value: rejected,
                            total: total,
                            color: Colors.red,
                            ratio: _safeRatio(rejected, total),
                          ),
                          const SizedBox(height: 12),
                          _ChartBarRow(
                            label: 'Pendentes',
                            value: pending,
                            total: total,
                            color: Colors.orange,
                            ratio: _safeRatio(pending, total),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BrandTheme.softPanel(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Check-ins',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await _exportPdf(
                                    name: name,
                                    address: address,
                                    startDate: startDate,
                                    startTime: startTime,
                                    endDate: endDate,
                                    endTime: endTime,
                                    status: status,
                                    radius: radius,
                                    total: total,
                                    approved: approved,
                                    rejected: rejected,
                                    pending: pending,
                                    checkins: checkins,
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Exportar PDF'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (checkins.isEmpty)
                            const Text(
                              'Nenhum check-in encontrado para este evento.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Aluno')),
                                  DataColumn(label: Text('Estado')),
                                  DataColumn(label: Text('Leitura')),
                                ],
                                rows: checkins.map((checkin) {
                                  final studentName =
                                      (checkin['student_name'] ?? 'Aluno')
                                          .toString();
                                  final checkinStatus =
                                      (checkin['status'] ?? '-').toString();
                                  final readAt = _formatDateTime(
                                    (checkin['read_at'] ??
                                            checkin['created_at'])
                                        ?.toString(),
                                  );

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(studentName)),
                                      DataCell(
                                        Text(
                                          checkinStatus,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _statusColor(checkinStatus),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(readAt)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Container(
        decoration: BrandTheme.softPanel(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartBarRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final double ratio;

  const _ChartBarRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (ratio * 100).toStringAsFixed(0) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('$value ($percent%)'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 14,
            color: color,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
