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

## Navegación manual

En tamaño mediano y grande el widget incluye dos botones para ir a la cita anterior o
siguiente. Usan App Intents (`ShiftQuoteIntent`) y acumulan un desplazamiento de franjas en
`UserDefaults`, que el provider suma al índice antes de calcular la cita. Como el
desplazamiento se aplica en franjas completas, la garantía de cobertura se mantiene.

El reloj sigue corriendo: tras navegar manualmente, la rotación automática continúa en la
siguiente frontera de 5 minutos. Hay un retardo de unos cientos de milisegundos entre el
clic y el refresco; es una limitación de WidgetKit.

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

Abre la app **rotatingquotes**: es un editor de lista donde añades, borras y reordenas
frases, cada una con su autor opcional. Los cambios se guardan solos y el widget se
recarga al instante.

Las frases viven en un JSON fuera del código:

```
~/Library/Containers/co.jgallo.rotatingquotes.widget/Data/Library/Application Support/co.jgallo.rotatingquotes/quotes.json
```

```json
[
  { "text": "I leave you the best of myself" },
  { "text": "The obstacle is the way", "author": "Marcus Aurelius" }
]
```

El campo `author` es opcional. La primera vez que abres la app se precargan 12 frases de
ejemplo; el botón **Restaurar predeterminadas** vuelve a ellas. Con `N` frases, el ciclo
completo dura `N × 5` minutos.

## Sandbox

Los dos targets tienen ajustes distintos, y es deliberado:

- **Widget: con sandbox.** macOS no registra extensiones de widget sin él. Verificado:
  con `ENABLE_APP_SANDBOX = NO` la extensión desaparece de `pluginkit` y de la galería.
- **App: sin sandbox.** Así puede escribir dentro del contenedor del widget, que es donde
  la extensión resuelve su propio `Application Support`.

Compartir datos entre una app en sandbox y su widget exigiría un App Group, que a su vez
requiere una cuenta de pago del Apple Developer Program. Este esquema lo evita, a costa de
que la app pierde el aislamiento del sandbox y deja de ser distribuible por el Mac App
Store.

Si algún día tienes cuenta de pago, lo correcto es volver a activar el sandbox de la app y
migrar a un App Group: solo cambia `directoryURL` en los dos `QuoteStore.swift`.

## Estructura

| Ruta | Descripción |
| --- | --- |
| `widget/Quote.swift` | Modelo y lógica de rotación |
| `widget/QuoteStore.swift` | Lectura del JSON compartido |
| `widget/widget.swift` | Timeline provider y vista del widget |
| `widget/ShiftQuoteIntent.swift` | Intent y almacenamiento del desplazamiento manual |
| `rotatingquotes/QuoteStore.swift` | Modelo, valores por defecto, guardado y recarga del widget |
| `rotatingquotes/ContentView.swift` | Editor de frases |
| `install.sh` | Compilación e instalación |

Tamaños soportados: pequeño, mediano y grande. El estilo se adapta a modo claro y oscuro.
Los botones de navegación solo aparecen en mediano y grande.
