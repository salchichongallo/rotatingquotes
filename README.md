# rotatingquotes

Widget de macOS que muestra una frase distinta cada 5 minutos.

## Cómo funciona la rotación

El tiempo se divide en franjas de 5 minutos. El índice de la franja determina el ciclo
(`franja / N`) y la posición dentro de él (`franja % N`), donde `N` es el número de citas.
El ciclo siembra un PRNG determinista (SplitMix64) que baraja los índices de las citas.

Esto garantiza que:

- Cada ciclo muestra **todas** las citas exactamente una vez.
- El orden es aleatorio y distinto en cada ciclo.
- Ninguna cita se repite dos franjas seguidas, ni siquiera entre ciclos.
- No hace falta persistencia ni estado compartido: la cita se calcula desde la fecha.

## Instalación

```bash
./install.sh
```

Compila en Release, instala la app en `/Applications` y registra el widget. Luego, clic
derecho en el escritorio → **Editar widgets** → busca **Quotes** y arrástralo.

Para desinstalar:

```bash
./install.sh --uninstall
```

Requiere Xcode en `/Applications`. No muevas ni borres `/Applications/rotatingquotes.app`:
el widget vive dentro de ese bundle.

## Editar las citas

Modifica `QuoteLibrary.all` en [widget/Quote.swift](widget/Quote.swift) y vuelve a ejecutar
`./install.sh`. El autor es opcional:

```swift
Quote(id: 12, text: "Tu frase aquí"),
Quote(id: 13, text: "Otra frase", author: "Alguien"),
```

Los `id` deben ser únicos. Con `N` citas, el ciclo completo dura `N × 5` minutos.

## Estructura

| Ruta | Descripción |
| --- | --- |
| `widget/Quote.swift` | Modelo, listado de citas y lógica de rotación |
| `widget/widget.swift` | Timeline provider y vista del widget |
| `rotatingquotes/` | App contenedora (mínima, solo aloja la extensión) |
| `install.sh` | Compilación e instalación |

Tamaños soportados: pequeño, mediano y grande. El estilo se adapta a modo claro y oscuro.
