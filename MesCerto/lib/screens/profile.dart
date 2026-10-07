import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../finance.dart';
import '../widgets/ui.dart';
import 'shell.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.fin;
    final c = f.colors;

    final items = <(String, IconData, VoidCallback?)>[
      ('Meu perfil', Icons.person_outline, null),
      ('Metas', Icons.flag_outlined, () => tabIndex.value = 2),
      ('Assinaturas', Icons.repeat, () => context.push('/subscriptions')),
      ('Notificações', Icons.notifications_none, () => context.push('/alerts')),
      ('Ajuda', Icons.help_outline, null),
      ('Sobre o app', Icons.info_outline, null),
    ];

    return AppScreen(
      title: 'Perfil',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppCard(
            child: Row(children: [
              Container(
                width: 55,
                height: 55,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                child: Text(f.initials, style: inter(18, kBold, c.primary)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.userName,
                          style: inter(16, kBold, c.foreground)),
                      const SizedBox(height: 4),
                      Text(f.userEmail,
                          style: inter(12, kReg, c.mutedForeground)),
                    ]),
              ),
              Icon(Icons.settings_outlined, size: 20, color: c.foreground),
            ]),
          ),
          AppCard(
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(children: [
              for (var i = 0; i < items.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: items[i].$3,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 57),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: i < items.length - 1
                        ? BoxDecoration(
                            border: Border(bottom: BorderSide(color: c.border)))
                        : null,
                    child: Row(children: [
                      IconCircle(icon: items[i].$2, color: c.primary, size: 31),
                      const SizedBox(width: 11),
                      Expanded(
                          child: Text(items[i].$1,
                              style: inter(13, kSemi, c.foreground))),
                      Icon(Icons.chevron_right,
                          size: 16, color: c.mutedForeground),
                    ]),
                  ),
                ),
              Container(
                constraints: const BoxConstraints(minHeight: 57),
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border))),
                child: Row(children: [
                  IconCircle(
                      icon: Icons.dark_mode_outlined,
                      color: c.primary,
                      size: 31),
                  const SizedBox(width: 11),
                  Expanded(
                      child: Text('Tema escuro',
                          style: inter(13, kSemi, c.foreground))),
                  Switch(
                    value: f.isDark,
                    onChanged: (_) =>
                        context.read<FinanceProvider>().toggleTheme(),
                    activeColor: Colors.white,
                    activeTrackColor: c.primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: c.border,
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 27),
          GestureDetector(
            onTap: () => confirmDialog(
              context,
              title: 'Sair da conta',
              message:
                  'Você precisará entrar novamente para ver seus dados.',
              confirmLabel: 'Sair',
              // Encerra a sessão no Supabase; o roteador volta ao início sozinho.
              onConfirm: () => context.read<FinanceProvider>().signOut(),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.logout, size: 19, color: c.danger),
              const SizedBox(width: 8),
              Text('Sair', style: inter(14, kBold, c.danger)),
            ]),
          ),
          const SizedBox(height: 22),
          Text('MêsCerto · versão 1.0.0',
              textAlign: TextAlign.center,
              style: inter(11, kReg, c.mutedForeground)),
        ],
      ),
    );
  }
}
