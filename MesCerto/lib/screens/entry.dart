import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../finance.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class NewEntryScreen extends StatefulWidget {
  final String? id;
  const NewEntryScreen({super.key, this.id});
  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  Transaction? _existing;
  EntryType _type = EntryType.expense;
  String _category = 'Alimentação';
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _date = TextEditingController(text: today());
  String _error = '';
  String _dateError = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final list = context.read<FinanceProvider>().transactions;
    final match = list.where((t) => t.id == widget.id);
    if (match.isNotEmpty) {
      final e = _existing = match.first;
      _type = e.type;
      _category = e.category;
      _description.text = e.description;
      _amount.text = amountToInput(e.amount);
      _date.text = e.date;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final numeric = parseMoney(_amount.text);
    if (_description.text.trim().isEmpty || numeric == null || numeric <= 0) {
      setState(() {
        _error = 'Preencha descrição e valor para continuar.';
        _dateError = '';
      });
      return;
    }
    final rawDate = _date.text.trim();
    final parsed = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)
        ? DateTime.tryParse(rawDate)
        : null;
    if (parsed == null) {
      setState(() {
        _error = '';
        _dateError = 'Use a data no formato AAAA-MM-DD.';
      });
      return;
    }
    setState(() {
      _error = '';
      _dateError = '';
      _saving = true;
    });
    final data = Transaction(
        id: '',
        type: _type,
        category: _category,
        description: _description.text.trim(),
        amount: numeric,
        date: dateToDb(parsed));
    final f = context.read<FinanceProvider>();
    final ok = _existing != null
        ? await f.updateTransaction(_existing!.id, data)
        : await f.addTransaction(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    final editing = _existing != null;
    // Categorias do tipo escolhido (despesa ou entrada), vindas do banco.
    final catNames = context.fin.categoryNamesFor(_type);

    Widget segment(
        String label, EntryType value, Color activeBg, Color activeFg) {
      final on = _type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _type = value;
            final names = context.read<FinanceProvider>().categoryNamesFor(value);
            if (names.isNotEmpty && !names.contains(_category)) {
              _category = names.first;
            }
          }),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: on ? activeBg : c.surface,
                borderRadius: BorderRadius.circular(13)),
            child: Text(label,
                style: inter(13, kBold, on ? activeFg : c.mutedForeground)),
          ),
        ),
      );
    }

    return AppScreen(
      title: editing ? 'Editar lançamento' : 'Novo lançamento',
      right: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close, size: 23, color: c.foreground)),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
                color: c.surfaceAlt, borderRadius: BorderRadius.circular(17)),
            child: Row(children: [
              segment('Despesa', EntryType.expense, c.dangerSoft, c.danger),
              segment('Entrada', EntryType.income, c.primarySoft, c.primary),
            ]),
          ),
          Text('Categoria', style: inter(13, kSemi, c.foreground)),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(11),
            margin: const EdgeInsets.only(bottom: 18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final name in catNames)
                  Builder(builder: (_) {
                    final meta = getCategoryMeta(name, c);
                    final selected = _category == name;
                    return GestureDetector(
                      onTap: () => setState(() => _category = name),
                      child: Container(
                        width: 89,
                        constraints: const BoxConstraints(minHeight: 75),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected
                              ? meta.color.withAlpha(0x1c)
                              : c.surfaceAlt,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: selected ? meta.color : c.border),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconCircle(
                                  icon: meta.icon, color: meta.color, size: 34),
                              const SizedBox(height: 5),
                              Text(name,
                                  textAlign: TextAlign.center,
                                  style: inter(
                                      10,
                                      kMed,
                                      selected
                                          ? c.foreground
                                          : c.mutedForeground)),
                            ]),
                      ),
                    );
                  }),
              ]),
            ),
          ),
          AppField(
              label: 'Descrição',
              hint: 'Ex: Mercado, restaurante...',
              controller: _description),
          AppField(
              label: 'Valor',
              hint: 'R\$ 0,00',
              controller: _amount,
              error: _error,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true)),
          AppField(
              label: 'Data',
              hint: 'AAAA-MM-DD',
              controller: _date,
              error: _dateError),
          PrimaryButton(
              label: _saving
                  ? 'Salvando...'
                  : (editing ? 'Salvar alterações' : 'Salvar lançamento'),
              onPressed: _save),
          if (editing)
            Padding(
              padding: const EdgeInsets.only(top: 19),
              child: Center(
                child: GestureDetector(
                  onTap: () => confirmDialog(
                    context,
                    title: 'Excluir lançamento?',
                    message: 'Esta ação não pode ser desfeita.',
                    confirmLabel: 'Excluir',
                    destructive: true,
                    onConfirm: () {
                      context
                          .read<FinanceProvider>()
                          .deleteTransaction(_existing!.id);
                      context.pop();
                    },
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.delete_outline, size: 17, color: c.danger),
                    const SizedBox(width: 7),
                    Text('Excluir lançamento',
                        style: inter(13, kSemi, c.danger)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
