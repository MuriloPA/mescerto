import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../finance.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'shell.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.fin;
    final c = f.colors;

    final totals = <String, double>{};
    for (final t in f.transactions.where((t) => t.type == EntryType.expense)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final top = (totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .toList();
    final usage = f.limitUsage;
    final recent = f.transactions.take(4).toList();
    const whiteMuted = Color(0xFFB8EBD7);

    return AppScreen(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bom dia,',
                            style: inter(14, kReg, c.mutedForeground)),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(text: '${f.firstName} ', children: [
                            TextSpan(
                                text: '•', style: TextStyle(color: c.primary))
                          ]),
                          style: inter(27, kBold, c.foreground),
                        ),
                      ]),
                  GestureDetector(
                    onTap: () => context.push('/alerts'),
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: c.border)),
                      child: Stack(alignment: Alignment.center, children: [
                        Icon(Icons.notifications_none,
                            size: 21, color: c.foreground),
                        if (f.limitUsage >= 0.8)
                          Positioned(
                            right: 9,
                            top: 8,
                            child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                    color: c.danger, shape: BoxShape.circle))),
                      ]),
                    ),
                  ),
                ]),
          ),
          AppCard(
            color: c.primaryDark,
            borderColor: c.primaryDark,
            padding: const EdgeInsets.all(20),
            minHeight: 175,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Saldo disponível', style: inter(13, kMed, whiteMuted)),
                const Icon(Icons.visibility_outlined,
                    size: 20, color: whiteMuted),
              ]),
              const SizedBox(height: 5),
              Text(formatCurrency(f.balance),
                  style: inter(31, kBold, Colors.white, ls: -0.5)),
              const SizedBox(height: 21),
              IntrinsicHeight(
                child: Row(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entradas', style: inter(13, kMed, whiteMuted)),
                        const SizedBox(height: 3),
                        Text(formatCurrency(f.incomeTotal),
                            style: inter(14, kSemi, Colors.white)),
                      ]),
                  const SizedBox(width: 25),
                  Container(width: 1, color: const Color(0xFF318A6D)),
                  const SizedBox(width: 25),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saídas', style: inter(13, kMed, whiteMuted)),
                        const SizedBox(height: 3),
                        Text(formatCurrency(f.expenseTotal),
                            style: inter(14, kSemi, Colors.white)),
                      ]),
                ]),
              ),
            ]),
          ),
          AppCard(
            margin: const EdgeInsets.only(top: 13),
            padding: const EdgeInsets.all(13),
            onTap: () => context.push('/alerts'),
            child: Row(children: [
              IconCircle(
                  icon: Icons.warning_amber_rounded,
                  color: c.warning,
                  size: 38),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Atenção aos seus gastos',
                          style: inter(13, kBold, c.foreground)),
                      const SizedBox(height: 3),
                      Text(
                          f.hasLimit
                              ? 'Você já usou ${(usage * 100).round()}% do seu limite mensal.'
                              : 'Defina um limite mensal na aba Metas.',
                          style: inter(12, kReg, c.mutedForeground)),
                    ]),
              ),
              Icon(Icons.chevron_right, size: 18, color: c.mutedForeground),
            ]),
          ),
          SectionHeader(
              title: 'Gastos por categoria',
              action: 'Ver tudo',
              onPressed: () => context.push('/categories')),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(children: [
              for (var i = 0; i < top.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/categories'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: i < top.length - 1
                        ? BoxDecoration(
                            border: Border(bottom: BorderSide(color: c.border)))
                        : null,
                    child: Builder(builder: (_) {
                      final meta = getCategoryMeta(top[i].key, c);
                      final percent = f.expenseTotal > 0
                          ? top[i].value / f.expenseTotal
                          : 0.0;
                      return Row(children: [
                        IconCircle(
                            icon: meta.icon, color: meta.color, size: 38),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(top[i].key,
                                      style: inter(13, kSemi, c.foreground)),
                                  Text(formatCurrency(top[i].value),
                                      style: inter(12, kSemi, c.foreground)),
                                ]),
                            const SizedBox(height: 8),
                            ProgressBar(
                                value: percent,
                                color: meta.color,
                                track: c.surfaceAlt),
                          ]),
                        ),
                      ]);
                    }),
                  ),
                ),
            ]),
          ),
          SectionHeader(
              title: 'Últimos lançamentos',
              action: 'Ver extrato',
              onPressed: () => tabIndex.value = 1),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(children: [
              for (final t in recent)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tabIndex.value = 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Builder(builder: (_) {
                      final meta = getCategoryMeta(t.category, c);
                      final income = t.type == EntryType.income;
                      return Row(children: [
                        IconCircle(
                            icon: meta.icon, color: meta.color, size: 40),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.description,
                                    style: inter(13, kSemi, c.foreground)),
                                const SizedBox(height: 4),
                                Text('${formatDate(t.date)} · ${t.category}',
                                    style: inter(11, kReg, c.mutedForeground)),
                              ]),
                        ),
                        Text(
                            '${income ? '+' : '-'} ${formatCurrency(t.amount)}',
                            style: inter(
                                12, kBold, income ? c.primary : c.foreground)),
                      ]);
                    }),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
