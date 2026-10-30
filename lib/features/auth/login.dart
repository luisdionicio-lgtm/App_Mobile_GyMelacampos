import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

const _navy = Color(0xff071e38);
const _red = Color(0xffd50920);

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
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = (size.height * .375).clamp(315.0, 360.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _navy,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: form,
                child: Column(
                  children: [
                    _LoginHero(height: heroHeight, topInset: topInset),
                    _loginCard(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginCard(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      22,
      30,
      22,
      MediaQuery.paddingOf(context).bottom + 24,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          child: TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              hintText: 'Correo del trabajador',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                v != null && v.contains('@') ? null : 'Escribe tu correo',
          ),
        ),
        const SizedBox(height: 14),
        _field(
          child: TextFormField(
            controller: password,
            obscureText: hidden,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              hintText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
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
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: busy ? null : login,
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(busy ? 'Conectando…' : 'Ingresar'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: busy ? null : widget.session.startDemo,
          style: OutlinedButton.styleFrom(
            foregroundColor: _red,
            side: const BorderSide(color: _red, width: 1.2),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Explorar demo de trabajador'),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xfff5f6f8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _red),
              SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Tu cuenta y permisos los crea el administrador desde la web.\nNo hay registro público de trabajadores.',
                  style: TextStyle(color: Color(0xff4c5566), height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Divider(color: Color(0xffe1e5ea)),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            onPressed: server,
            style: TextButton.styleFrom(foregroundColor: _red),
            icon: const Icon(Icons.dns_outlined),
            label: const Text('Configurar conexión'),
          ),
        ),
      ],
    ),
  );

  Widget _field({required Widget child}) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(primary: _red),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffb9bec6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
      ),
    ),
    child: child,
  );
}

class _LoginHero extends StatelessWidget {
  final double height, topInset;
  const _LoginHero({required this.height, required this.topInset});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/login-navy-marble.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: ClipPath(
            clipper: const _BlackMarbleFacet(),
            child: Image.asset(
              'assets/login-black-marble-v2.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: ClipPath(
            clipper: const _MarbleWedge(),
            child: Image.asset(
              'assets/login-white-marble-v2.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: ClipPath(
            clipper: const _RedSlash(),
            child: const ColoredBox(color: _red),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, topInset + 4, 24, 18),
          child: LayoutBuilder(
            builder: (context, limits) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: limits.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LoginBrand(),
                    const SizedBox(height: 12),
                    Container(width: 44, height: 3, color: _red),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Tu taller,\ncontigo'),
                          TextSpan(
                            text: '.',
                            style: TextStyle(color: _red),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontWeight: FontWeight.w700,
                        fontSize: 42,
                        height: 1.04,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Medidas, materiales y propuestas.\nToda la visita en un solo lugar.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'G',
              style: TextStyle(color: _red),
            ),
            TextSpan(
              text: '&M',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        style: TextStyle(
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.w700,
          fontSize: 34,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Melacampos',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Playfair Display',
                fontWeight: FontWeight.w700,
                fontSize: 21,
              ),
            ),
            Text(
              'Mármol · Granito · Cuarzo',
              maxLines: 1,
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MarbleWedge extends CustomClipper<Path> {
  const _MarbleWedge();
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, size.height * .18)
    ..lineTo(size.width, size.height * .98)
    ..lineTo(size.width * .66, size.height * .50)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RedSlash extends CustomClipper<Path> {
  const _RedSlash();
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, size.height * .10)
    ..lineTo(size.width, size.height * .18)
    ..lineTo(size.width * .66, size.height * .50)
    ..lineTo(size.width * .62, size.height * .45)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BlackMarbleFacet extends CustomClipper<Path> {
  const _BlackMarbleFacet();
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .66, size.height * .50)
    ..lineTo(size.width, size.height * .98)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width * .40, size.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
