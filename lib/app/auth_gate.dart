/// Decide entre el flujo de acceso y el de estudio.
///
/// Observa `authStateProvider`, así que la transición ocurre sola al entrar o
/// salir: ninguna pantalla tiene que navegar a mano tras autenticarse, lo que
/// elimina de raíz la clase de error en que la sesión cambia y la interfaz se
/// queda donde estaba.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth/auth_service.dart';
import '../ui/providers/auth_providers.dart';
import '../ui/screens/sign_in_screen.dart';
import 'home_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<StudentIdentity?> auth = ref.watch(authStateProvider);

    return switch (auth) {
      AsyncData<StudentIdentity?>(value: final StudentIdentity? identity) =>
        identity == null ? const SignInScreen() : const HomeShell(),

      // Un fallo al observar la sesión deja entrar al flujo de acceso en lugar de
      // mostrar un error: desde ahí la persona puede reintentar, mientras que una
      // pantalla de error sin salida la deja atrapada.
      AsyncError<StudentIdentity?>() => const SignInScreen(),

      _ => const _SplashScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
