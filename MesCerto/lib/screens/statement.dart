import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../finance.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({super.key});
  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  EntryType? _filter; // null = todos

  @override
  Widget build(BuildContext context) {
    final f = context.fin;
    final c = f.colors;
    final items = f.transactions
        .where((t) => _filter == null || t.type == _filter)
        .toList();

    Widget chip(String label, EntryType? value) {
      final selected = _filter == value;
      return GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: selected ? c.primary : c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border)),
          child: Text(label,
              style: inter(
                  12, kSemi, selected ? Colors.white : c.mutedForeground)),
        ),
      );
    }

    return AppScreen(
      title: 'Extrato',
      right: IconButton(
          onPressed: () => context.push('/categories'),
          icon: Icon(Icons.tune, size: 22, color: c.foreground)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Wrap(spacing: 8, children: [
            chip('Todos', null),
            chip('Entradas', EntryType.income),
            chip('Saídas', EntryType.expense)
          ]),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                      onTap: f.prevMonth,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.chevron_left,
                              size: 19, color: c.foreground))),
                  Text(formatMonth(f.month),
                      style: inter(15, kBold, c.foreground)),
                  GestureDetector(
                      onTap: f.nextMonth,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.chevron_right,
                              size: 19, color: c.foreground))),
                ]),
          ),
          if (items.isEmpty)
            const EmptyState(
                title: 'Nenhum lançamento',
                description:
                    'Adicione sua primeira entrada ou despesa para acompanhar seu mês.',
                icon: Icons.receipt_long_outlined)
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(children: [
                for (final t in items)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/new-entry?id=${t.id}'),
                    onLongPress: () => confirmDialog(
                      context,
                      title: 'Excluir lançamento?',
                      message: 'O lançamento "${t.description}" será removido.',
                      confirmLabel: 'Excluir',
                      destructive: true,
                      onConfirm: () => context
                          .read<FinanceProvider>()
                          .deleteTransaction(t.id),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Builder(builder: (_) {
                        final meta = getCategoryMeta(t.category, c);
                        final income = t.type == EntryType.income;
                        return Row(children: [
                          IconCircle(
                              icon: meta.icon, color: meta.color, size: 42),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.description,
                                      style: inter(13, kSemi, c.foreground)),
                                  const SizedBox(height: 5),
                                  Text('${formatDate(t.date)} · ${t.category}',
                                      style:
                                          inter(11, kReg, c.mutedForeground)),
                                ]),
                          ),
                          Text(
                              '${income ? '+' : '-'} ${formatCurrency(t.amount)}',
                              style: inter(12, kBold,
                                  income ? c.primary : c.foreground)),
                          const SizedBox(width: 5),
                          Icon(Icons.chevron_right,
                              size: 15, color: c.mutedForeground),
                        ]);
                      }),
                    ),
                  ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text('Toque para editar · segure para excluir',
                textAlign: TextAlign.center,
                style: inter(11, kReg, c.mutedForeground)),
          ),
        ],
      ),
    );
  }
}
