import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

class LoginPage extends StatefulWidget {
  final Session session;
  const LoginPage(this.session, {super.key});
  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false, hidden = true;
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.session.login(email.text, password.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> server() async {
    final controller = TextEditingController(text: widget.session.api.base);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Servidor de G&M'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'URL del servidor'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        await widget.session.api.configure(result);
        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Brand(large: true),
                  const SizedBox(height: 36),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/stone.png',
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Tu taller,\ncontigo.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Medidas, materiales y propuestas. Toda la visita en un solo lugar.',
                    style: TextStyle(height: 1.6, color: Color(0xff6C6963)),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Correo del trabajador',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Escribe tu correo',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    obscureText: hidden,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(
                          hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Escribe tu contraseña' : null,
                    onFieldSubmitted: (_) => login(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : login,
                      child: Text(busy ? 'Conectando…' : 'Ingresar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: busy ? null : widget.session.startDemo,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 50),
                      ),
                      child: const Text('Explorar demo de trabajador'),
                    ),
                  ),
                  const Note(
                    'Tu cuenta y permisos los crea el administrador desde la web. No hay registro público de trabajadores.',
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: server,
                      icon: const Icon(Icons.dns_outlined),
                      label: const Text('Configurar conexión'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
