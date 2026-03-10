import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateEventModal extends StatefulWidget {
  const CreateEventModal({super.key});

  @override
  State<CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<CreateEventModal> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');
  final MapController _mapController = MapController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _loading = false;
  bool _searchingAddress = false;

  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _displayDate(DateTime? date) {
    if (date == null) return 'Selecionar data';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _displayTime(TimeOfDay? time) {
    if (time == null) return 'Selecionar hora';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _startDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a morada antes de pesquisar.')),
      );
      return;
    }

    setState(() => _searchingAddress = true);

    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=$encodedQuery',
      );

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Não foi possível localizar a morada.');
      }

      final List<dynamic> data = jsonDecode(response.body);

      if (data.isEmpty) {
        throw Exception('Nenhum resultado encontrado para a morada informada.');
      }

      final result = data.first as Map<String, dynamic>;
      final lat = double.tryParse(result['lat'].toString());
      final lon = double.tryParse(result['lon'].toString());
      final displayName = (result['display_name'] ?? query).toString();

      if (lat == null || lon == null) {
        throw Exception('Não foi possível obter latitude e longitude.');
      }

      if (!mounted) return;

      setState(() {
        _latitude = lat;
        _longitude = lon;
        _resolvedAddress = displayName;
      });

      _mapController.move(LatLng(lat, lon), 16);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _searchingAddress = false);
      }
    }
  }

  Future<void> createEvent() async {
    final supabase = Supabase.instance.client;

    final name = _nameController.text.trim();
    final address = (_resolvedAddress ?? _addressController.text).trim();
    final radius = double.tryParse(_radiusController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome obrigatório')),
      );
      return;
    }

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Morada obrigatória')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesquise a morada para obter o local no mapa.')),
      );
      return;
    }

    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina a data e hora de início')),
      );
      return;
    }

    if (_endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina a data e hora de fim')),
      );
      return;
    }

    if (radius == null || radius <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um raio válido em metros.')),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data/hora de fim deve ser posterior ao início.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await supabase
          .from('events')
          .insert({
            'name': name,
            'adress': address,
            'start_date': _formatDate(_startDate!),
            'start_time': _formatTime(_startTime!),
            'end_date': _formatDate(_endDate!),
            'end_time': _formatTime(_endTime!),
            'status': 'active',
            'radius_meters': radius,
            'latitude': _latitude,
            'longitude': _longitude,
          })
          .select()
          .single();

      if (!mounted) return;
      Navigator.pop(context, response);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Criar Evento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do evento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        onChanged: (_) {
                          setState(() {
                            _resolvedAddress = null;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Morada do evento',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _searchingAddress ? null : _searchAddress,
                        icon: const Icon(Icons.search),
                        label: _searchingAddress
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Buscar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_latitude != null && _longitude != null) ...[
                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(_latitude!, _longitude!),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.istec_checkin',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_latitude!, _longitude!),
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_pin,
                                size: 42,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_resolvedAddress != null && _resolvedAddress!.isNotEmpty)
                    Text(
                      'Morada encontrada: $_resolvedAddress',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Latitude: ${_latitude!.toStringAsFixed(6)} | Longitude: ${_longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _radiusController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Raio permitido (metros)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickStartDate,
                        child: Text('Data Início: ${_displayDate(_startDate)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickStartTime,
                        child: Text('Hora do checkin: ${_displayTime(_startTime)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickEndDate,
                        child: Text('Data Fim: ${_displayDate(_endDate)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickEndTime,
                        child: Text('Hora do encerramento: ${_displayTime(_endTime)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : createEvent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar Evento'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}