import 'dart:async';
import 'package:flutter/material.dart';
// "show" evita conflito de nomes (ex.: Subscription) com o pacote do Supabase.
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, SupabaseClient, AuthState, PostgrestException;
import 'theme.dart';

/// Permite mostrar avisos (SnackBar) a partir do provider.
final messengerKey = GlobalKey<ScaffoldMessengerState>();

enum EntryType { expense, income }

// Banco: 'despesa' / 'receita'.
String _typeToDb(EntryType t) => t == EntryType.expense ? 'despesa' : 'receita';
EntryType _typeFromDb(String s) =>
    s == 'receita' ? EntryType.income : EntryType.expense;

/// Color(0xFF4387DC) <-> '#4387DC' (como as cores são guardadas no banco).
String colorToHex(Color c) =>
    '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String _two(int n) => n.toString().padLeft(2, '0');

/// DateTime -> 'AAAA-MM-DD' (formato da coluna date do PostgreSQL).
String dateToDb(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// Dias entre hoje e a data 'AAAA-MM-DD' (negativo = já passou).
int daysUntil(String date) {
  final d = DateTime.tryParse(date);
  if (d == null) return 0;
  final now = DateTime.now();
  final diff = DateTime(d.year, d.month, d.day)
      .difference(DateTime(now.year, now.month, now.day));
  return (diff.inHours / 24).round();
}

/// "hoje", "amanhã", "em 5 dias"...
String inDaysText(int d) {
  if (d == 0) return 'hoje';
  if (d == 1) return 'amanhã';
  if (d < 0) return 'atrasada há ${-d} dia${d == -1 ? '' : 's'}';
  return 'em $d dias';
}

class _AppError implements Exception {
  final String message;
  _AppError(this.message);
}

String _friendly(Object e) {
  if (e is _AppError) return e.message;
  if (e is PostgrestException) {
    final m = e.message.toLowerCase();
    if (e.code == '23505') return 'Já existe um registro igual a este.';
    if (e.code == '23514') return 'Algum valor informado é inválido.';
    if (e.code == '23503') {
      return 'Este registro está em uso e não pode ser alterado.';
    }
    if (e.code == '42501' || m.contains('row-level security')) {
      return 'Você não tem permissão para fazer isso.';
    }
    return 'Não foi possível salvar. Tente novamente.';
  }
  return 'Sem conexão ou erro inesperado. Tente novamente.';
}

// ---------------------------------------------------------------- modelos

class Transaction {
  final String id;
  final EntryType type;
  final String category; // nome da categoria
  final String description;
  final double amount;
  final String date; // 'AAAA-MM-DD'

  const Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });
}

class Goal {
  final String id;
  final String name;
  final double target;
  final double saved;
  final String icon; // chave de appIcons
  final Color color;

  const Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.icon,
    required this.color,
  });
}

class Subscription {
  final String id, name, nextCharge, icon;
  final double amount;
  final Color color;
  const Subscription(
      this.id, this.name, this.amount, this.nextCharge, this.icon, this.color);
}

class CategoryItem {
  final String id, name, icon;
  final EntryType type;
  final Color color;
  final bool archived;
  const CategoryItem(
      this.id, this.name, this.type, this.icon, this.color, this.archived);
}

// --------------------------------------------------------------- provider

/// Guarda em memória os dados do usuário logado e os mantém sincronizados
/// com o Supabase. As telas continuam lendo getters síncronos (como antes);
/// quem muda é a origem dos dados: o banco, e não o celular.
class FinanceProvider extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSub;
  String? _loadedUser;

  List<CategoryItem> _cats = [];
  List<Transaction> _tx = []; // só do mês exibido
  List<Goal> _goals = [];
  List<Subscription> _subs = [];
  DateTime _month = monthStart(DateTime.now());
  double? _limit; // limite geral do mês exibido (null = sem limite)
  String? _limitId;
  String _name = '';
  bool _dark = false;

  bool loading = false;
  bool hydrated = false;

  FinanceProvider() {
    _authSub = _db.auth.onAuthStateChange.listen((AuthState s) {
      final session = s.session;
      if (session != null) {
        if (_loadedUser != session.user.id) loadAll();
      } else {
        _clear();
      }
    });
    if (_db.auth.currentSession != null) loadAll();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ---- leitura (usada pelas telas)

  String get userName => _name;
  String get firstName {
    final p = _name.trim().split(RegExp(r'\s+'));
    return p.isEmpty || p.first.isEmpty ? 'você' : p.first;
  }

  String get initials {
    final p = _name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }

  String get userEmail => _db.auth.currentUser?.email ?? '';

  DateTime get month => _month;
  bool get hasLimit => _limit != null;
  double get monthlyLimit => _limit ?? 0;

  List<Transaction> get transactions => List.unmodifiable(_tx);
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Subscription> get subscriptions => List.unmodifiable(_subs);
  bool get isDark => _dark;
  AppPalette get colors => _dark ? AppPalette.dark : AppPalette.light;

  // Tudo abaixo é do MÊS selecionado e calculado a partir dos lançamentos.
  double get incomeTotal => _tx
      .where((t) => t.type == EntryType.income)
      .fold(0.0, (s, t) => s + t.amount);
  double get expenseTotal => _tx
      .where((t) => t.type == EntryType.expense)
      .fold(0.0, (s, t) => s + t.amount);
  double get balance => incomeTotal - expenseTotal;

  /// Despesas ÷ limite (1.0 = 100%). Sem limite definido: 0.
  double get limitUsage => hasLimit ? expenseTotal / _limit! : 0.0;

  /// Próxima assinatura a renovar (a partir de hoje).
  Subscription? get nextSubscription {
    final list = _subs.where((s) => daysUntil(s.nextCharge) >= 0).toList()
      ..sort((a, b) => a.nextCharge.compareTo(b.nextCharge));
    return list.isEmpty ? null : list.first;
  }

  List<String> categoryNamesFor(EntryType t) => _cats
      .where((c) => c.type == t && !c.archived)
      .map((c) => c.name)
      .toList();

  String? _catIdFor(String name, EntryType t) {
    for (final c in _cats) {
      if (c.name == name && c.type == t) return c.id;
    }
    return null;
  }

  String _catName(String id) {
    for (final c in _cats) {
      if (c.id == id) return c.name;
    }
    return 'Sem categoria';
  }

  // ---- carregamento

  Future<void> loadAll() async {
    final u = _db.auth.currentUser;
    if (u == null) return;
    _loadedUser = u.id;
    loading = true;
    notifyListeners();
    try {
      final p = await _db.from('perfis').select().eq('id', u.id).maybeSingle();
      _name = (p?['nome'] as String?) ?? (u.email ?? '').split('@').first;
      _dark = p?['tema'] == 'escuro';

      final cats =
          await _db.from('categorias').select().order('ordem').order('nome');
      _cats = cats
          .map<CategoryItem>((r) => CategoryItem(
                r['id'] as String,
                r['nome'] as String,
                _typeFromDb(r['tipo'] as String),
                r['icone'] as String,
                hexToColor(r['cor'] as String),
                r['arquivada'] as bool,
              ))
          .toList();

      await _loadGoals();
      await _loadSubs();
      await _loadMonth();
      hydrated = true;
    } catch (e) {
      _toast(_friendly(e));
    }
    loading = false;
    notifyListeners();
  }

  void _clear() {
    _loadedUser = null;
    _cats = [];
    _tx = [];
    _goals = [];
    _subs = [];
    _limit = null;
    _limitId = null;
    _name = '';
    hydrated = false;
    loading = false;
    notifyListeners();
  }

  Future<void> _loadMonth() async {
    final start = dateToDb(_month);
    final end = dateToDb(DateTime(_month.year, _month.month + 1, 1));

    final rows = await _db
        .from('lancamentos')
        .select()
        .gte('data', start)
        .lt('data', end)
        .order('data', ascending: false)
        .order('criado_em', ascending: false);
    _tx = rows
        .map<Transaction>((r) => Transaction(
              id: r['id'] as String,
              type: _typeFromDb(r['tipo'] as String),
              category: _catName(r['categoria_id'] as String),
              description: r['descricao'] as String,
              amount: (r['valor'] as num).toDouble(),
              date: r['data'] as String,
            ))
        .toList();

    final lim = await _db
        .from('limites_mensais')
        .select()
        .eq('mes', start)
        .isFilter('categoria_id', null)
        .maybeSingle();
    _limitId = lim?['id'] as String?;
    _limit = lim == null ? null : (lim['valor'] as num).toDouble();
  }

  Future<void> _loadGoals() async {
    final rows = await _db
        .from('metas_economia')
        .select()
        .order('criado_em', ascending: false);
    _goals = rows
        .map<Goal>((r) => Goal(
              id: r['id'] as String,
              name: r['nome'] as String,
              target: (r['valor_alvo'] as num).toDouble(),
              saved: (r['valor_guardado'] as num).toDouble(),
              icon: r['icone'] as String,
              color: hexToColor(r['cor'] as String),
            ))
        .toList();
  }

  Future<void> _loadSubs() async {
    final rows = await _db
        .from('assinaturas')
        .select()
        .eq('ativa', true)
        .order('proxima_cobranca');
    _subs = rows
        .map<Subscription>((r) => Subscription(
              r['id'] as String,
              r['nome'] as String,
              (r['valor'] as num).toDouble(),
              r['proxima_cobranca'] as String,
              r['icone'] as String,
              hexToColor(r['cor'] as String),
            ))
        .toList();
  }

  // ---- mês

  Future<void> setMonth(DateTime m) async {
    _month = monthStart(m);
    loading = true;
    notifyListeners();
    try {
      await _loadMonth();
    } catch (e) {
      _toast(_friendly(e));
    }
    loading = false;
    notifyListeners();
  }

  void prevMonth() => setMonth(DateTime(_month.year, _month.month - 1, 1));
  void nextMonth() => setMonth(DateTime(_month.year, _month.month + 1, 1));

  // ---- lançamentos

  Map<String, dynamic> _txToRow(Transaction t) {
    final catId = _catIdFor(t.category, t.type);
    if (catId == null) throw _AppError('Categoria não encontrada.');
    return {
      'categoria_id': catId,
      'tipo': _typeToDb(t.type),
      'descricao': t.description,
      'valor': double.parse(t.amount.toStringAsFixed(2)),
      'data': t.date,
    };
  }

  // Depois de salvar, mostra o mês do lançamento (assim ele aparece na tela).
  Future<void> _afterTxChange(String date) async {
    final d = DateTime.tryParse(date);
    if (d != null) _month = monthStart(d);
    await _loadMonth();
    notifyListeners();
  }

  Future<bool> addTransaction(Transaction t) => _run(() async {
        await _db.from('lancamentos').insert(_txToRow(t));
        await _afterTxChange(t.date);
      });

  Future<bool> updateTransaction(String id, Transaction t) => _run(() async {
        await _db.from('lancamentos').update(_txToRow(t)).eq('id', id);
        await _afterTxChange(t.date);
      });

  Future<bool> deleteTransaction(String id) => _run(() async {
        await _db.from('lancamentos').delete().eq('id', id);
        await _loadMonth();
        notifyListeners();
      });

  // ---- limite mensal (geral)

  Future<bool> setMonthlyLimit(double v) => _run(() async {
        if (v <= 0) throw _AppError('Informe um valor maior que zero.');
        final value = double.parse(v.toStringAsFixed(2));
        if (_limitId != null) {
          await _db
              .from('limites_mensais')
              .update({'valor': value}).eq('id', _limitId!);
        } else {
          await _db
              .from('limites_mensais')
              .insert({'mes': dateToDb(_month), 'valor': value});
        }
        await _loadMonth();
        notifyListeners();
      });

  // ---- metas

  Future<bool> addGoal(Goal g) => _run(() async {
        await _db.from('metas_economia').insert({
          'nome': g.name,
          'valor_alvo': double.parse(g.target.toStringAsFixed(2)),
          'valor_guardado': g.saved,
          'icone': g.icon,
          'cor': colorToHex(g.color),
        });
        await _loadGoals();
        notifyListeners();
      });

  /// Soma [amount] ao valor guardado da meta.
  Future<bool> addToGoal(String id, double amount) => _run(() async {
        if (amount <= 0) throw _AppError('Informe um valor maior que zero.');
        final g = _goals.firstWhere((e) => e.id == id);
        final novo = double.parse((g.saved + amount).toStringAsFixed(2));
        await _db
            .from('metas_economia')
            .update({'valor_guardado': novo}).eq('id', id);
        await _loadGoals();
        notifyListeners();
      });

  // ---- assinaturas

  Future<bool> addSubscription(String name, double amount, String nextCharge) =>
      _run(() async {
        await _db.from('assinaturas').insert({
          'nome': name,
          'valor': double.parse(amount.toStringAsFixed(2)),
          'proxima_cobranca': nextCharge,
        });
        await _loadSubs();
        notifyListeners();
      });

  Future<bool> deleteSubscription(String id) => _run(() async {
        await _db.from('assinaturas').delete().eq('id', id);
        await _loadSubs();
        notifyListeners();
      });

  // ---- perfil / sessão

  void toggleTheme() {
    _dark = !_dark;
    notifyListeners();
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    _run(() async {
      await _db
          .from('perfis')
          .update({'tema': _dark ? 'escuro' : 'claro'}).eq('id', uid);
    });
  }

  Future<void> signOut() async {
    try {
      await _db.auth.signOut();
    } catch (e) {
      _toast(_friendly(e));
    }
  }

  // ---- utilidades internas

  /// Executa uma ação no banco; em caso de erro, avisa o usuário e devolve false.
  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      _toast(_friendly(e));
      return false;
    }
  }

  void _toast(String msg) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}
