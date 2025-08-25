import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    final auth = Supabase.instance.client.auth;
    final db = Supabase.instance.client;
    try {
      if (_isSignUp) {
        final res = await auth.signUp(email: _email.text.trim(), password: _pass.text);
        final userId = res.user?.id;
        if (userId != null) {
          // upsert del profile para evitar warnings y tener datos mínimos
          await db.from('profiles').upsert({'id': userId, 'display_name': ''});
        }
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _pass.text);
      }
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avanti')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AutofillGroup(
          child: Column(
            children: [
              Text(_isSignUp ? 'Create account' : 'Sign in', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                autofillHints: const [AutofillHints.email],
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(_isSignUp ? 'Sign up' : 'Sign in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? 'I already have an account' : 'Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
