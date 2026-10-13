/// Formulario de correo y contraseña, compartido por acceso y registro.
///
/// Existe compartido porque FR-004 exige que al fallar **no se pierda lo que la
/// persona escribió**, y eso depende de que los controladores de texto sobrevivan
/// al error. Duplicar el formulario duplicaría también la ocasión de romper esa
/// garantía en uno de los dos lados.
library;

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';

class EmailPasswordForm extends StatefulWidget {
  const EmailPasswordForm({
    required this.submitLabel,
    required this.onSubmit,
    required this.submitting,
    this.errorMessage,
    this.onChanged,
    this.footer,
    super.key,
  });

  final String submitLabel;

  /// Se invoca con los valores ya recortados.
  final void Function(String email, String password) onSubmit;

  final bool submitting;

  /// Mensaje del último fallo, o nulo si no hay ninguno.
  final String? errorMessage;

  /// Se invoca al escribir, para descartar el error anterior.
  final VoidCallback? onChanged;

  /// Enlaces bajo el botón, como «¿no tienes cuenta?».
  final Widget? footer;

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.submitting) return;
    if (_formKey.currentState?.validate() != true) return;
    widget.onSubmit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _email,
            decoration: InputDecoration(labelText: l10n.emailLabel),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            enabled: !widget.submitting,
            onChanged: (_) => widget.onChanged?.call(),
            validator: (String? value) {
              final String text = value?.trim() ?? '';
              if (text.isEmpty) return l10n.emailLabel;
              // Validación mínima a propósito: la comprobación de verdad la hace
              // el servidor, y una expresión regular estricta rechaza correos
              // válidos y poco comunes.
              if (!text.contains('@') || !text.contains('.')) {
                return l10n.authErrorInvalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            enabled: !widget.submitting,
            onChanged: (_) => widget.onChanged?.call(),
            onFieldSubmitted: (_) => _submit(),
            validator: (String? value) =>
                (value ?? '').isEmpty ? l10n.passwordLabel : null,
          ),
          if (widget.errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            // Semántica de alerta para que el lector de pantalla lo anuncie en
            // lugar de dejarlo pasar como texto decorativo.
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.error_outline, color: colors.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.submitting ? null : _submit,
            child: widget.submitting
                ? const SizedBox(
                    height: minTouchTarget / 2,
                    width: minTouchTarget / 2,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
          if (widget.footer != null) ...<Widget>[
            const SizedBox(height: 8),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}
