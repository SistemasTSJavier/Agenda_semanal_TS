import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../services/supabase_service.dart';
import 'reservation_form_screen.dart';
import 'reservation_detail_screen.dart';

const int hourStart = 8;
const int hourEnd = 18;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;
  List<Reservation> _reservations = [];
  bool _loading = true;
  StreamSubscription<void>? _realtimeSub;
  String get _fechaKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadDay(fromRealtime: false);
    _realtimeSub = SupabaseService.reservationsChanged.listen((_) {
      if (mounted) _loadDay(fromRealtime: true);
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDay({bool fromRealtime = false}) async {
    setState(() => _loading = true);
    try {
      final list = await SupabaseService.getReservationsForDay(_fechaKey);
      if (mounted) {
        setState(() {
          _reservations = list;
          _loading = false;
        });
        if (fromRealtime) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lista actualizada'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    }
  }

  List<Reservation> _reservationsForHour(int hour) {
    final prefix = hour.toString().padLeft(2, '0');
    return _reservations.where((r) {
      final h = r.hora.split(':').first;
      return h == prefix || r.hora.startsWith('$prefix:');
    }).toList();
  }

  Reservation? _reservationAtHour(int hour) {
    final list = _reservationsForHour(hour);
    return list.isEmpty ? null : list.first;
  }

  void _prevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _loadDay(fromRealtime: false);
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _loadDay(fromRealtime: false);
    });
  }

  Future<void> _openNewReservation() async {
    final result = await Navigator.of(context).push<Reservation?>(
      MaterialPageRoute(
        builder: (context) => ReservationFormScreen(initialDate: _selectedDate),
      ),
    );
    if (result != null) {
      await _loadDay(fromRealtime: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservación guardada: ${result.asunto} (${result.fecha} ${result.hora})'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _openDetail(result);
    }
  }

  Future<void> _openDetail(Reservation r) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReservationDetailScreen(reservation: r),
      ),
    );
    if (deleted == true) _loadDay(fromRealtime: false);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d \'de\' MMMM \'de\' y', 'es').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _buildHeader(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => SupabaseService.signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'SALA DE JUNTAS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildToolbar(dateLabel),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'HORARIO RESERVADO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildDayTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewReservation,
        icon: const Icon(Icons.add),
        label: const Text('Nueva reservación'),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'TACTICAL',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Image.asset(
            'assets/logo.png',
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.calendar_month, size: 32, color: Colors.grey[700]),
          ),
        ),
        const Text(
          'SUPPORT',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(String dateLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevDay),
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextDay),
        ],
      ),
    );
  }

  Widget _buildDayTable() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 56, child: Text('HORA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black))),
              Expanded(flex: 12, child: Text('ORGANIZADOR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black))),
              Expanded(flex: 15, child: Text('ASUNTO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black))),
              Expanded(flex: 10, child: Text('INVITADOS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black))),
            ],
          ),
        ),
        ...List.generate(hourEnd - hourStart + 1, (index) {
          final hour = hourStart + index;
          final hourLabel = '${hour.toString().padLeft(2, '0')}:00';
          final r = _reservationAtHour(hour);
          return InkWell(
            onTap: r != null ? () => _openDetail(r) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(hourLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  Expanded(flex: 12, child: Text(r?.responsable ?? '—', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 15, child: Text(r?.asunto ?? '—', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 10, child: Text((r?.participantes.trim().isEmpty ?? true) ? '—' : r!.participantes, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
