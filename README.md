# languages_app

Aplicación de aprendizaje de idiomas construida en Flutter/Dart. Lleva a una persona
hispanohablante desde cero absoluto hasta hablar con fluidez, siguiendo una ruta por
niveles del Marco Común Europeo de Referencia (A1 → C2).

**Idiomas iniciales:** inglés, francés y portugués. La arquitectura está diseñada para
añadir idiomas nuevos sin tocar el motor de aprendizaje.

## Estado

En desarrollo inicial. La gobernanza del proyecto está definida en
[`.specify/memory/constitution.md`](.specify/memory/constitution.md) y es de lectura
obligatoria antes de contribuir.

## Stack

| Pieza | Elección |
|---|---|
| Lenguaje | Dart |
| Framework | Flutter (SDK `^3.12.2`) |
| Editor | Visual Studio Code |
| Plataformas primarias | Android y Web |
| Hosting | Firebase Hosting → `languages.buildlark.com` |

## Arquitectura

Las dependencias fluyen en un solo sentido: `ui → engine → core ← content`.

```
lib/
  core/                  modelos y contratos compartidos
  engine/                lógica de aprendizaje (puntuación, SRS, desbloqueos)
  ui/                    pantallas y widgets
  content/<idioma>/      datos didácticos por idioma (en, fr, pt, ...)
  services/              persistencia, audio, Firebase
  main.dart              punto de entrada
```

El motor no conoce ningún idioma concreto: todo el contenido vive en
`lib/content/<idioma>/` implementando los contratos de `lib/core/`.

## Comandos

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar en el dispositivo o emulador conectado:

```bash
flutter run
```

Puertas de calidad obligatorias antes de cada commit:

```bash
flutter analyze && flutter test
```

## Flujo de trabajo

El desarrollo sigue [Spec Kit](https://github.com/github/spec-kit):
`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.

`main` solo avanza por pull request fusionado. La regla se refuerza con hooks
versionados en `.githooks/`, que **cada clon nuevo debe activar una vez**:

```bash
git config core.hooksPath .githooks
```

Son una guarda local, no protección de servidor: `pre-commit` bloquea commits en
`main` y `pre-push` bloquea pushes y borrados de `main`. Ambos admiten salida de
emergencia (`ALLOW_MAIN_COMMIT=1`, `ALLOW_MAIN_PUSH=1`).
