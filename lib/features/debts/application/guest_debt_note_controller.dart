import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/guest_store.dart';
import '../domain/guest_debt_note_model.dart';

final guestDebtNoteControllerProvider =
    StateNotifierProvider<GuestDebtNoteController, List<GuestDebtNoteModel>>(
      (ref) => GuestDebtNoteController(ref),
    );

class GuestDebtNoteController extends StateNotifier<List<GuestDebtNoteModel>> {
  GuestDebtNoteController(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;
  static const _uuid = Uuid();

  GuestStore get _store => _ref.read(guestStoreProvider);

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final notes = await _store.loadDebtNotes();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) state = notes;
  }

  Future<void> addNote({
    required String title,
    required double amount,
    required GuestDebtNoteType type,
    DateTime? deadline,
    String? note,
  }) async {
    final item = GuestDebtNoteModel(
      id: _uuid.v4(),
      title: title.trim(),
      amount: amount,
      type: type,
      createdAt: DateTime.now(),
      deadline: deadline,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
    state = [item, ...state];
    await _store.saveDebtNotes(state);
  }

  Future<void> deleteNote(String id) async {
    state = state.where((note) => note.id != id).toList();
    await _store.saveDebtNotes(state);
  }
}
