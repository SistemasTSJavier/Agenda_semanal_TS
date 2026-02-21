import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../services/supabase_service.dart';

class ReservationDetailScreen extends StatelessWidget {
  final Reservation reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reservación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta reservación?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await SupabaseService.deleteReservation(reservation.id);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = SupabaseService.currentUserEmail == reservation.reservadoPor;
    final fechaFormatted = _formatDate(reservation.fecha);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de reservación')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(label: 'Fecha', value: fechaFormatted),
            _DetailRow(label: 'Hora', value: reservation.hora),
            _DetailRow(label: 'Organizador', value: reservation.responsable),
            _DetailRow(label: 'Asunto', value: reservation.asunto),
            if (reservation.participantes.isNotEmpty) _DetailRow(label: 'Invitados', value: reservation.participantes),
            if (reservation.nombreContacto.isNotEmpty) _DetailRow(label: 'Nombre (notificación)', value: reservation.nombreContacto),
            if (reservation.correoNotificacion.isNotEmpty) _DetailRow(label: 'Correo (notificación)', value: reservation.correoNotificacion),
            _DetailRow(label: 'Reservado por', value: reservation.reservadoPor),
            const Spacer(),
            if (canDelete)
              FilledButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final parts = iso.split('-').map(int.parse).toList();
    if (parts.length != 3) return iso;
    final d = DateTime(parts[0], parts[1], parts[2]);
    return DateFormat('d \'de\' MMMM \'de\' y', 'es').format(d);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
