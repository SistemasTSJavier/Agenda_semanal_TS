import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../services/supabase_service.dart';

const int hourStart = 8;
const int hourEnd = 18;

class ReservationFormScreen extends StatefulWidget {
  final DateTime initialDate;

  const ReservationFormScreen({super.key, required this.initialDate});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  late DateTime _fecha;
  late int _hora;
  final _responsableController = TextEditingController();
  final _asuntoController = TextEditingController();
  final _participantesController = TextEditingController();
  final _nombreContactoController = TextEditingController();
  final _correoNotificacionController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fecha = widget.initialDate;
    _hora = 8;
    _responsableController.text = SupabaseService.currentUserEmail ?? '';
  }

  @override
  void dispose() {
    _responsableController.dispose();
    _asuntoController.dispose();
    _participantesController.dispose();
    _nombreContactoController.dispose();
    _correoNotificacionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _save() async {
    final responsable = _responsableController.text.trim();
    final asunto = _asuntoController.text.trim();
    if (responsable.isEmpty || asunto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organizador y asunto son obligatorios')),
      );
      return;
    }
    final fechaStr = DateFormat('yyyy-MM-dd').format(_fecha);
    final horaStr = '${_hora.toString().padLeft(2, '0')}:00';
    final existing = await SupabaseService.getReservationsForDay(fechaStr);
    final slotTaken = existing.any((r) {
      final h = r.hora.split(':').first;
      return h == _hora.toString().padLeft(2, '0') || r.hora.startsWith('${_hora.toString().padLeft(2, '0')}:');
    });
    if (slotTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya hay una reserva a las $horaStr ese día. Solo se permite una reserva por hora.'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final r = Reservation(
        id: '',
        fecha: fechaStr,
        hora: horaStr,
        responsable: responsable,
        asunto: asunto,
        participantes: _participantesController.text.trim(),
        reservadoPor: SupabaseService.currentUserEmail ?? '',
        nombreContacto: _nombreContactoController.text.trim(),
        correoNotificacion: _correoNotificacionController.text.trim(),
      );
      final created = await SupabaseService.createReservation(r);
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva reservación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              value: _hora,
              decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder()),
              items: List.generate(hourEnd - hourStart + 1, (i) {
                final h = hourStart + i;
                return DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00'));
              }),
              onChanged: (v) => setState(() => _hora = v ?? 8),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('d MMMM y', 'es').format(_fecha)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _responsableController,
              decoration: const InputDecoration(
                labelText: 'Organizador (predeterminado: correo de inicio de sesión)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _asuntoController,
              decoration: const InputDecoration(labelText: 'Asunto', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _participantesController,
              decoration: const InputDecoration(labelText: 'Invitados', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Text('Notificación por correo (opcional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreContactoController,
              decoration: const InputDecoration(labelText: 'Nombre de la persona (para notificación)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _correoNotificacionController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo (notificación de reunión)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar reservación'),
            ),
          ],
        ),
      ),
    );
  }
}
