import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../finance.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.fin;
    final c = f.colors;
    final usage = f.limitUsage.clamp(0.0, 1.0).toDouble();
    return AppScreen(
      title: 'Metas',
      right: IconButton(
          onPressed: () => context.push('/new-goal'),
          icon: Icon(Icons.add, size: 25, color: c.foreground)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppCard(
            color: c.primarySoft,
            borderColor: c.primarySoft,
            padding: const EdgeInsets.all(18),
            // Toque para definir/alterar o limite do mês exibido.
            onTap: () => showLimitDialog(context),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Meta de gastos do mês',
                      style: inter(12, kSemi, c.primary)),
                  const SizedBox(height: 5),
                  Text(f.hasLimit ? formatCurrency(f.monthlyLimit) : 'Definir limite',
                      style: inter(23, kBold, c.foreground)),
                ]),
                IconCircle(
                    icon: Icons.account_balance_wallet_outlined,
                    color: c.primary,
                    size: 42),
              ]),
              const SizedBox(height: 18),
              ProgressBar(
                  value: usage, color: c.primary, track: c.surface, height: 8),
              const SizedBox(height: 8),
              Text(
                  f.hasLimit
                      ? '${formatCurrency(f.expenseTotal)} gastos de ${formatCurrency(f.monthlyLimit)}'
                      : '${formatCurrency(f.expenseTotal)} gastos no mês · toque para definir o limite',
                  style: inter(11, kReg, c.mutedForeground)),
            ]),
          ),
          SectionHeader(
              title: 'Minhas metas',
              action: 'Nova meta',
              onPressed: () => context.push('/new-goal')),
          if (f.goals.isEmpty)
            const EmptyState(
                title: 'Nenhuma meta',
                description:
                    'Toque em "Nova meta" para criar seu primeiro objetivo.',
                icon: Icons.flag_outlined),
          for (final g in f.goals)
            Builder(builder: (_) {
              final progress = (g.saved / g.target).clamp(0.0, 1.0).toDouble();
              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => showAddToGoalDialog(context, g),
                child: Column(children: [
                  Row(children: [
                    IconCircle(
                        icon: appIcons[g.icon] ?? Icons.flag_outlined,
                        color: g.color,
                        size: 43),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: inter(14, kBold, c.foreground)),
                            const SizedBox(height: 5),
                            Text(
                                '${formatCurrency(g.saved)} de ${formatCurrency(g.target)}',
                                style: inter(12, kSemi, c.mutedForeground)),
                          ]),
                    ),
                    Text('${(progress * 100).round()}%',
                        style: inter(14, kBold, c.primary)),
                  ]),
                  const SizedBox(height: 18),
                  ProgressBar(
                      value: progress,
                      color: g.color,
                      track: c.surfaceAlt,
                      height: 8),
                  const SizedBox(height: 9),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            progress >= 1
                                ? 'Meta concluída'
                                : '${formatCurrency(g.target - g.saved)} restantes',
                            style: inter(11, kReg, c.mutedForeground)),
                        Text('Toque para guardar valor',
                            style: inter(11, kSemi, c.primary)),
                      ]),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

class NewGoalScreen extends StatefulWidget {
  const NewGoalScreen({super.key});
  @override
  State<NewGoalScreen> createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final numeric = parseMoney(_target.text);
    if (_name.text.trim().isNotEmpty && numeric != null && numeric > 0) {
      setState(() => _saving = true);
      final f = context.read<FinanceProvider>();
      final ok = await f.addGoal(Goal(
          id: '',
          name: _name.text.trim(),
          target: numeric,
          saved: 0,
          icon: 'flag',
          color: f.colors.primary));
      if (!mounted) return;
      setState(() => _saving = false);
      if (ok) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return AppScreen(
      title: 'Nova meta',
      right: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close, size: 23, color: c.foreground)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'Defina um objetivo para acompanhar seu progresso e celebrar cada avanço.',
              style: inter(14, kReg, c.mutedForeground, height: 1.5)),
          const SizedBox(height: 26),
          AppField(
              label: 'Nome da meta',
              hint: 'Ex: Viagem dos sonhos',
              controller: _name),
          AppField(
              label: 'Valor objetivo',
              hint: 'R\$ 0,00',
              controller: _target,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true)),
          PrimaryButton(label: 'Criar meta', onPressed: _save),
        ]),
      ),
    );
  }
}
