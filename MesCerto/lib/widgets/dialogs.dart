import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../finance.dart';
import '../format.dart';
import '../theme.dart';
import 'ui.dart';

InputDecoration _dec(AppPalette c, String hint) => InputDecoration(
      hintText: hint,
      hintStyle: inter(14, kReg, c.mutedForeground),
      filled: true,
      fillColor: c.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border)),
    );

const _money = TextInputType.numberWithOptions(decimal: true);

/// Define (ou altera) o limite geral do mês exibido.
Future<void> showLimitDialog(BuildContext context) {
  final f = context.read<FinanceProvider>();
  final c = f.colors;
  final ctrl = TextEditingController(
      text: f.hasLimit ? amountToInput(f.monthlyLimit) : '');
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      title: Text('Limite de ${formatMonth(f.month)}',
          style: inter(17, kBold, c.foreground)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: _money,
        style: inter(15, kReg, c.foreground),
        decoration: _dec(c, 'R\$ 0,00'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Cancelar', style: inter(14, kSemi, c.mutedForeground))),
        TextButton(
          onPressed: () {
            final v = parseMoney(ctrl.text);
            if (v == null || v <= 0) return;
            Navigator.of(ctx).pop();
            f.setMonthlyLimit(v);
          },
          child: Text('Salvar', style: inter(14, kBold, c.primary)),
        ),
      ],
    ),
  );
}

/// Soma um valor ao "guardado" de uma meta.
Future<void> showAddToGoalDialog(BuildContext context, Goal g) {
  final f = context.read<FinanceProvider>();
  final c = f.colors;
  final ctrl = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      title: Text('Guardar em "${g.name}"',
          style: inter(17, kBold, c.foreground)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: _money,
        style: inter(15, kReg, c.foreground),
        decoration: _dec(c, 'Quanto você guardou? R\$ 0,00'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Cancelar', style: inter(14, kSemi, c.mutedForeground))),
        TextButton(
          onPressed: () {
            final v = parseMoney(ctrl.text);
            if (v == null || v <= 0) return;
            Navigator.of(ctx).pop();
            f.addToGoal(g.id, v);
          },
          child: Text('Adicionar', style: inter(14, kBold, c.primary)),
        ),
      ],
    ),
  );
}

/// Cadastro de assinatura mensal (nome, valor e próxima cobrança).
Future<void> showNewSubscriptionDialog(BuildContext context) {
  final f = context.read<FinanceProvider>();
  final c = f.colors;
  final name = TextEditingController();
  final value = TextEditingController();
  final date = TextEditingController(text: today());
  String error = '';
  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Nova assinatura', style: inter(17, kBold, c.foreground)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                autofocus: true,
                style: inter(15, kReg, c.foreground),
                decoration: _dec(c, 'Nome (ex.: Netflix)')),
            const SizedBox(height: 10),
            TextField(
                controller: value,
                keyboardType: _money,
                style: inter(15, kReg, c.foreground),
                decoration: _dec(c, 'Valor mensal (R\$ 0,00)')),
            const SizedBox(height: 10),
            TextField(
                controller: date,
                style: inter(15, kReg, c.foreground),
                decoration: _dec(c, 'Próxima cobrança (AAAA-MM-DD)')),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error,
                    style: TextStyle(fontSize: 12, color: c.danger)),
              ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar',
                  style: inter(14, kSemi, c.mutedForeground))),
          TextButton(
            onPressed: () {
              final v = parseMoney(value.text);
              final okDate = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date.text) &&
                  DateTime.tryParse(date.text) != null;
              if (name.text.trim().isEmpty || v == null || v <= 0) {
                setState(() => error = 'Informe o nome e um valor maior que zero.');
                return;
              }
              if (!okDate) {
                setState(() => error = 'Use a data no formato AAAA-MM-DD.');
                return;
              }
              Navigator.of(ctx).pop();
              f.addSubscription(name.text.trim(), v, date.text);
            },
            child: Text('Salvar', style: inter(14, kBold, c.primary)),
          ),
        ],
      ),
    ),
  );
}
