import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../finance.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.fin;
    final c = f.colors;
    final usage = f.limitUsage;
    final nearLimit = f.hasLimit && usage >= 0.8;

    // Todos os alertas são calculados na hora a partir dos dados do banco.
    final alerts = <(IconData, Color, String, String)>[];

    if (f.hasLimit) {
      alerts.add((
        Icons.account_balance_wallet_outlined,
        c.primary,
        'Limite mensal',
        '${(usage * 100).round()}% do limite utilizado · ${formatCurrency(f.expenseTotal)} / ${formatCurrency(f.monthlyLimit)}'
      ));
    }

    final next = f.nextSubscription;
    if (next != null) {
      alerts.add((
        appIcons[next.icon] ?? Icons.repeat,
        next.color,
        'Assinatura ${next.name}',
        'Renovação ${inDaysText(daysUntil(next.nextCharge))} · ${formatCurrency(next.amount)}'
      ));
    }

    if (f.goals.isNotEmpty) {
      final g = f.goals.first;
      final percent = (g.saved / g.target * 100).round();
      alerts.add((
        appIcons[g.icon] ?? Icons.flag_outlined,
        g.color,
        'Meta ${g.name}',
        '$percent% da meta concluída · ${formatCurrency(g.saved)} / ${formatCurrency(g.target)}'
      ));
    }

    return AppScreen(
      title: 'Alertas',
      right: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close, size: 23, color: c.foreground)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (nearLimit)
            AppCard(
              color: c.warningSoft,
              borderColor: c.warningSoft,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconCircle(
                        icon: Icons.warning_amber_rounded,
                        color: c.warning,
                        size: 40),
                    const SizedBox(height: 13),
                    Text(
                        usage >= 1
                            ? 'Você passou do limite'
                            : 'Você está perto do limite',
                        style: inter(16, kBold, c.foreground)),
                    const SizedBox(height: 5),
                    Text('Acompanhe seus gastos e mantenha o equilíbrio do mês.',
                        style: inter(12, kReg, c.foreground, height: 1.5)),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () => context.push('/categories'),
                      child: Container(
                        height: 36,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(color: c.primary),
                            borderRadius: BorderRadius.circular(18)),
                        child: Text('Ver categoria',
                            style: inter(12, kBold, c.primary)),
                      ),
                    ),
                  ]),
            ),
          if (alerts.isEmpty)
            const EmptyState(
                title: 'Nenhum alerta',
                description:
                    'Defina um limite mensal na aba Metas e cadastre suas assinaturas para receber avisos.',
                icon: Icons.notifications_none),
          for (final a in alerts)
            AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                IconCircle(icon: a.$1, color: a.$2, size: 39),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.$3, style: inter(13, kBold, c.foreground)),
                        const SizedBox(height: 5),
                        Text(a.$4,
                            style: inter(11, kReg, c.mutedForeground,
                                height: 1.45)),
                      ]),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.fin;
    final c = f.colors;
    final expenses = f.transactions.where((t) => t.type == EntryType.expense);
    final total = expenses.fold(0.0, (s, t) => s + t.amount);

    return AppScreen(
      title: 'Categorias',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Gastos do mês selecionado, por categoria (percentual sobre o
          // total de despesas do mês).
          for (final name in f.categoryNamesFor(EntryType.expense))
            Builder(builder: (_) {
              final amount = expenses
                  .where((t) => t.category == name)
                  .fold(0.0, (s, t) => s + t.amount);
              final percent = total > 0 ? amount / total : 0.0;
              final meta = getCategoryMeta(name, c);
              return AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                onTap: () => context.push('/new-entry'),
                child: Row(children: [
                  IconCircle(icon: meta.icon, color: meta.color, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name,
                                    style: inter(13, kBold, c.foreground)),
                                Text(formatCurrency(amount),
                                    style: inter(12, kSemi, c.foreground)),
                              ]),
                          const SizedBox(height: 9),
                          ProgressBar(
                              value: percent,
                              color: meta.color,
                              track: c.surfaceAlt),
                          const SizedBox(height: 5),
                          Text('${(percent * 100).round()}% dos gastos',
                              style: inter(11, kReg, c.mutedForeground)),
                        ]),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: c.mutedForeground),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.fin;
    final c = f.colors;
    final subs = f.subscriptions;
    final total = subs.fold(0.0, (s, e) => s + e.amount);
    final next = f.nextSubscription;

    return AppScreen(
      title: 'Assinaturas',
      right: IconButton(
          onPressed: () => showNewSubscriptionDialog(context),
          icon: Icon(Icons.add, size: 25, color: c.foreground)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppCard(
            color: c.primarySoft,
            borderColor: c.primarySoft,
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total em assinaturas por mês',
                  style: inter(12, kSemi, c.primary)),
              const SizedBox(height: 5),
              Text(formatCurrency(total),
                  style: inter(25, kBold, c.foreground)),
              const SizedBox(height: 5),
              Text(
                  '${subs.length} serviço${subs.length == 1 ? '' : 's'} ativo${subs.length == 1 ? '' : 's'}',
                  style: inter(11, kReg, c.mutedForeground)),
            ]),
          ),
          const SectionHeader(title: 'Ativas'),
          if (subs.isEmpty)
            const EmptyState(
                title: 'Nenhuma assinatura',
                description:
                    'Toque no + para cadastrar sua primeira assinatura.',
                icon: Icons.repeat)
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Column(children: [
                for (final s in subs)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => confirmDialog(
                      context,
                      title: 'Remover assinatura?',
                      message: '"${s.name}" deixará de aparecer na sua lista.',
                      confirmLabel: 'Remover',
                      destructive: true,
                      onConfirm: () => context
                          .read<FinanceProvider>()
                          .deleteSubscription(s.id),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        IconCircle(
                            icon: appIcons[s.icon] ?? Icons.repeat,
                            color: s.color,
                            size: 42),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: inter(13, kBold, c.foreground)),
                                const SizedBox(height: 4),
                                Text('Renova em ${formatDate(s.nextCharge)}',
                                    style: inter(11, kReg, c.mutedForeground)),
                              ]),
                        ),
                        Text(formatCurrency(s.amount),
                            style: inter(12, kBold, c.foreground)),
                      ]),
                    ),
                  ),
              ]),
            ),
          if (subs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Segure para remover',
                  textAlign: TextAlign.center,
                  style: inter(11, kReg, c.mutedForeground)),
            ),
          if (next != null)
            AppCard(
              color: c.warningSoft,
              borderColor: c.warningSoft,
              margin: const EdgeInsets.only(top: 17),
              padding: const EdgeInsets.all(13),
              child: Row(children: [
                IconCircle(
                    icon: Icons.warning_amber_outlined,
                    color: c.warning,
                    size: 34),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        '${next.name} renova ${inDaysText(daysUntil(next.nextCharge))}.',
                        style: inter(12, kMed, c.foreground, height: 1.5))),
              ]),
            ),
        ],
      ),
    );
  }
}
