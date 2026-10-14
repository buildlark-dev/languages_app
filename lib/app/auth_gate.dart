/// Decide entre el flujo de acceso y el de estudio.
///
/// Observa `authStateProvider`, así que la transición ocurre sola al entrar o
/// salir: ninguna pantalla tiene que navegar a mano tras autenticarse, lo que
/// elimina de raíz la clase de error en que la sesión cambia y la interfaz se
/// queda donde estaba.
///
/// ## Y aun así se quedaba donde estaba
///
/// Esa promesa tenía un agujero: la puerta cambia **su** contenido, pero no
/// puede hacer nada contra lo que haya encima. El registro se abre con
/// `Navigator.push` sobre el acceso, así que al crear la cuenta la puerta
/// cambiaba a la pantalla de inicio **debajo** de la de registro, que seguía
/// tapándola. Lo reportado al verificar SC-001: «deja crear cuenta pero la
/// pantalla se queda estática, toca ir atrás».
///
/// Lo mismo en espejo al cerrar sesión desde Ajustes: la puerta vuelve al
/// acceso debajo de una pantalla de ajustes que sigue visible, con los datos de
/// alguien que ya no tiene sesión.
///
/// Por eso la puerta ahora **también limpia la pila**: cuando la sesión aparece
/// o desaparece, todo lo que se hubiera abierto encima se cierra. Es la mitad
/// que faltaba para que la frase de arriba fuera cierta.
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
    // Se escucha además de observar: observar cambia lo que hay dentro de la
    // puerta, escuchar permite reaccionar a que la sesión cambió.
    ref.listen<AsyncValue<StudentIdentity?>>(authStateProvider, (
      AsyncValue<StudentIdentity?>? previous,
      AsyncValue<StudentIdentity?> next,
    ) {
      final bool hadSession = previous?.value != null;
      final bool hasSession = next.value != null;
      if (hadSession == hasSession) return;

      // Fuera de la construcción: navegar mientras se construye el árbol es un
      // error de Flutter, y el aviso llega durante ella.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final NavigatorState? navigator = Navigator.maybeOf(context);
        if (navigator == null || !navigator.mounted) return;
        navigator.popUntil((Route<void> route) => route.isFirst);
      });
    });

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
