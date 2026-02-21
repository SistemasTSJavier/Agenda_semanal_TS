import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reservation.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  static String? get currentUserId => _client.auth.currentUser?.id;
  static String? get currentUserEmail => _client.auth.currentUser?.email;

  static String? get currentUserDisplayName {
    final meta = _client.auth.currentUser?.userMetadata;
    if (meta == null) return null;
    return meta['full_name'] as String? ?? meta['name'] as String? ?? currentUserEmail;
  }

  static Future<void> signOut() => _client.auth.signOut();

  static Future<List<Reservation>> getReservationsForDay(String fecha) async {
    final res = await _client
        .from('reservations')
        .select()
        .eq('fecha', fecha)
        .order('hora');
    return (res as List)
        .map((e) => Reservation.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<Reservation> createReservation(Reservation r) async {
    final data = r.toMap();
    final res = await _client.from('reservations').insert(data).select().single();
    final created = Reservation.fromMap(Map<String, dynamic>.from(res as Map));
    if (created.correoNotificacion.trim().isNotEmpty) {
      _invokeSendReservationEmail(created);
    }
    return created;
  }

  static void _invokeSendReservationEmail(Reservation created) {
    final body = created.toMap();
    _client.functions.invoke('send-reservation-email', body: body).then((_) {}).catchError((Object e) {
      assert(false, 'Email de notificación: $e');
    });
  }

  static Future<void> deleteReservation(String id) async {
    await _client.from('reservations').delete().eq('id', id);
  }

  static Stream<void> get reservationsChanged {
    late final StreamController<void> controller;
    late final RealtimeChannel channel;
    controller = StreamController<void>.broadcast(onListen: () {
      channel = _client.channel('reservations-changes').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reservations',
        callback: (_) => controller.add(null),
      );
      channel.subscribe();
    }, onCancel: () {
      channel.unsubscribe();
    });
    return controller.stream;
  }
}
