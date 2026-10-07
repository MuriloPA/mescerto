import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/ui.dart';
import 'goals.dart';
import 'home.dart';
import 'profile.dart';
import 'statement.dart';

/// Aba atual (0 Início, 1 Extrato, 2 Metas, 3 Perfil). Global para qualquer tela poder trocar de aba.
final tabIndex = ValueNotifier<int>(0);

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    final bottom = MediaQuery.of(context).padding.bottom;

    Widget item(int i, String label, IconData icon, int current) {
      final color = current == i ? c.primary : c.mutedForeground;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => tabIndex.value = i,
          child: Column(children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(label, style: inter(10, kSemi, color)),
          ]),
        ),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, current, _) => Scaffold(
        backgroundColor: c.background,
        body: Column(children: [
          Expanded(
            child: IndexedStack(index: current, children: const [
              DashboardPage(),
              StatementPage(),
              GoalsPage(),
              ProfilePage(),
            ]),
          ),
          SizedBox(
            height: 84 + bottom,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                top: 14,
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                      color: c.surface,
                      border: Border(top: BorderSide(color: c.border))),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        item(0, 'Início', Icons.home_outlined, current),
                        item(1, 'Extrato', Icons.bar_chart_rounded, current),
                        const Expanded(child: SizedBox()),
                        item(2, 'Metas', Icons.flag_outlined, current),
                        item(3, 'Perfil', Icons.person_outline, current),
                      ]),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => context.push('/new-entry'),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.background, width: 4)),
                    child: const Icon(Icons.add, color: Colors.white, size: 25),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
