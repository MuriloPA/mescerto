import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, AuthException;
import '../widgets/ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.primaryDark, const Color(0xFF004B37)]),
        ),
        child: Stack(children: [
          Positioned(
            bottom: 70,
            left: -100,
            child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF118B67).withAlpha(178))),
          ),
          Positioned(
            bottom: 10,
            right: -100,
            child: Container(
                width: 330,
                height: 160,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(160),
                    color: const Color(0xFF0D7356).withAlpha(140))),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Column(children: [
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset('assets/images/icon.png',
                                  width: 92, height: 92)),
                          const SizedBox(height: 18),
                          Text.rich(
                            TextSpan(text: 'Mês', children: const [
                              TextSpan(
                                  text: 'Certo',
                                  style: TextStyle(color: Color(0xFF44E7AA)))
                            ]),
                            style: inter(38, kBold, Colors.white, ls: -1.2),
                          ),
                          const SizedBox(height: 14),
                          Text('Organize seu dinheiro\naté o fim do mês.',
                              textAlign: TextAlign.center,
                              style: inter(17, kReg, const Color(0xFFD4F8E8),
                                  height: 1.5)),
                        ]),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                        color: const Color(0xFF31E2A2),
                        borderRadius: BorderRadius.circular(29)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Entrar',
                              style: inter(16, kBold, const Color(0xFF004D38))),
                          const SizedBox(width: 10),
                          Text('→',
                              style: inter(22, kReg, const Color(0xFF004D38))),
                        ]),
                  ),
                ),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Ainda não tem uma conta? ',
                      style: inter(13, kReg, const Color(0xFFB8EBD7))),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text('Criar conta',
                        style: inter(13, kSemi, const Color(0xFFB8EBD7))
                            .copyWith(
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFFB8EBD7))),
                  ),
                ]),
                const SizedBox(height: 22),
                Text('Seu dinheiro, no lugar certo.',
                    style: inter(12, kReg, const Color(0xFF8BCEB4))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Traduz os erros do Supabase Auth para mensagens simples em português.
String authErrorMessage(AuthException e) {
  final m = e.message.toLowerCase();
  if (m.contains('invalid login credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (m.contains('already registered') ||
      m.contains('already been registered')) {
    return 'Este e-mail já está cadastrado.';
  }
  if (m.contains('password should be at least') ||
      m.contains('weak password')) {
    return 'A senha precisa ter pelo menos 6 caracteres.';
  }
  if (m.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar.';
  }
  if (m.contains('rate limit') || m.contains('too many')) {
    return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
  }
  if (m.contains('email') && m.contains('invalid')) {
    return 'Digite um e-mail válido.';
  }
  return 'Não foi possível concluir. Tente novamente.';
}

void _soon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$what em breve.')));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _visible = false;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_loading) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Informe e-mail e senha.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      // O roteador também redireciona sozinho quando a sessão muda.
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Sem conexão. Verifique sua internet e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, size: 22, color: c.foreground)),
            const SizedBox(height: 22),
            const LogoMark(),
            const SizedBox(height: 34),
            Text('Bem-vindo de volta!',
                style: inter(28, kBold, c.foreground, ls: -0.5)),
            const SizedBox(height: 8),
            Text('Faça login para continuar.',
                style: inter(15, kReg, c.mutedForeground)),
            const SizedBox(height: 32),
            AppField(
                label: 'E-mail',
                hint: 'seu@email.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress),
            AppField(
              label: 'Senha',
              hint: 'Digite sua senha',
              controller: _password,
              obscure: !_visible,
              error: _error,
              suffix: IconButton(
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: c.mutedForeground),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                // Recuperação de senha exige configurar o link de retorno no
                // painel do Supabase e no app; fica para uma próxima etapa.
                onTap: () => _soon(context, 'Recuperação de senha'),
                child: Text('Esqueci minha senha',
                    style: inter(13, kSemi, c.primary)),
              ),
            ),
            const SizedBox(height: 23),
            PrimaryButton(
                label: _loading ? 'Entrando...' : 'Entrar', onPressed: _enter),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Row(children: [
                Expanded(child: Container(height: 1, color: c.border)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        Text('ou', style: inter(13, kReg, c.mutedForeground))),
                Expanded(child: Container(height: 1, color: c.border)),
              ]),
            ),
            PrimaryButton(
                label: 'Continuar com Google',
                icon: Icons.g_mobiledata,
                secondary: true,
                onPressed: () => _soon(context, 'Login com Google')),
            const SizedBox(height: 10),
            PrimaryButton(
                label: 'Continuar com Apple',
                icon: Icons.apple,
                secondary: true,
                onPressed: () => _soon(context, 'Login com Apple')),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Não tem uma conta? ',
                  style: inter(14, kReg, c.mutedForeground)),
              GestureDetector(
                  onTap: () => context.push('/register'),
                  child:
                      Text('Cadastre-se', style: inter(13, kSemi, c.primary))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_loading) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    String? problem;
    if (name.isEmpty) {
      problem = 'Informe seu nome.';
    } else if (!email.contains('@') || !email.contains('.')) {
      problem = 'Digite um e-mail válido.';
    } else if (password.length < 6) {
      problem = 'A senha precisa ter pelo menos 6 caracteres.';
    } else if (password != _confirm.text) {
      problem = 'As senhas não são iguais.';
    }
    if (problem != null) {
      setState(() => _error = problem!);
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      // O nome vai junto: o gatilho do banco usa ele para criar o perfil.
      final res = await Supabase.instance.client.auth
          .signUp(email: email, password: password, data: {'nome': name});
      if (!mounted) return;
      if (res.session != null) {
        context.go('/home');
      } else {
        // Projeto com "confirmar e-mail" ligado: precisa confirmar antes.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Conta criada! Confirme seu e-mail para entrar.')));
        context.pushReplacement('/login');
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Sem conexão. Verifique sua internet e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, size: 22, color: c.foreground)),
            const SizedBox(height: 22),
            const LogoMark(),
            const SizedBox(height: 36),
            Text('Crie sua conta',
                style: inter(28, kBold, c.foreground, ls: -0.5)),
            const SizedBox(height: 8),
            Text('Comece a organizar sua vida financeira.',
                style: inter(15, kReg, c.mutedForeground)),
            const SizedBox(height: 30),
            AppField(
                label: 'Nome',
                hint: 'Como podemos te chamar?',
                controller: _name),
            AppField(
                label: 'E-mail',
                hint: 'seu@email.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress),
            AppField(
                label: 'Senha',
                hint: 'Crie uma senha segura',
                controller: _password,
                obscure: true),
            AppField(
                label: 'Confirme sua senha',
                hint: 'Digite novamente',
                controller: _confirm,
                obscure: true,
                error: _error),
            PrimaryButton(
                label: _loading ? 'Criando...' : 'Criar minha conta',
                onPressed: _create),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Já tem uma conta? ',
                  style: inter(14, kReg, c.mutedForeground)),
              GestureDetector(
                  onTap: () => context.pushReplacement('/login'),
                  child: Text('Entrar', style: inter(13, kSemi, c.primary))),
            ]),
          ]),
        ),
      ),
    );
  }
}
