# Clippy Debugging Guide

## 🐛 Current Status

El sistema Clippy ahora tiene **debug logging completo**. Todos los componentes imprimen su estado en la consola.

---

## 📊 Verificación de Integración

### Paso 1: Verificar Autoloads

Abre el juego y verifica que la consola muestre:

```
[ClippyBridge] Initializing...
[ClippyBridge] ✓ Found Clippy autoload
[ClippyBridge] ✓ Connected to EventBus signals
[ClippyBridge] Ready and listening for events
```

Si NO aparece:

- Verifica que `project.godot` tenga las líneas:
  ```
  Clippy="*res://src/clippy/ClippyController.gd"
  ClippyBridge="*res://src/clippy/ClippyEventBridge.gd"
  ```
- **Reinicia** Godot para que cargue los autoloads

### Paso 2: Verificar ClippyUI

La consola debe mostrar:

```
[ClippyUI] Initializing...
[ClippyUI] Panel hidden initially
[ClippyUI] ✓ Connected to Clippy signals
[ClippyUI] Ready and waiting for messages
```

Si NO aparece:

- Verifica que `ClippyUI.tscn` esté en la escena (Desktop o MainMenu)
- Mira el árbol de nodos en el editor

---

## 🧪 Prueba Manual

### Método 1: Usar TestClippyEmitter

1. Abre `MainMenu.tscn` o `Desktop.tscn` en Godot
2. Añade nodo hijo: `Node` → Attach Script → `res://src/clippy/TestClippyEmitter.gd`
3. Ejecuta el juego
4. Presiona teclas:
   - **T** = Tutorial
   - **M** = Minigame
   - **E** = Error
   - **P** = Progress
   - **A** = Achievement
   - **N** = Navigation Ready (vía EventBus)

### Método 2: Emitir desde Consola Godot

En la consola de Godot (durante ejecución):

```gdscript
# Crear evento directamente
var event = ClippyEvent.new()
event.event_type = ClippyEvent.EventType.TUTORIAL_START
event.context_id = "test"
Clippy.handle_event(event)

# O emitir vía EventBus
EventBus.navigation_ready.emit()
```

---

## 📝 Flujo de Debugging Esperado

Cuando emitas un evento, deberías ver en consola:

```
1. [ClippyBridge] → Sending event: ClippyEvent[...]
2. [ClippyController] Received event: ClippyEvent[...]
3. [ClippyController] Event is valid, adding to queue
4. [ClippyController] Generating text for event...
5. [ClippyController] Generated text: ...
6. [ClippyController] Emitting ready_to_display signal
7. [ClippyUI] Received message: ...
8. [ClippyUI] Showing message
9. [ClippyUI] Panel animated in
10. [ClippyUI] Auto-dismiss timer started (8.0s)
```

Si el flujo se detiene en algún paso, ese es el problema.

---

## 🔧 Problemas Comunes

### Problema: No aparece nada en consola

**Solución:**

- Reinicia Godot completamente
- Ve a Project > Reload Current Project
- Verifica que los archivos existan en `src/clippy/`

### Problema: ClippyBridge no conecta

```
[ClippyBridge] ✗ Clippy autoload not found!
```

**Solución:**

- Abre `Project Settings > Autoload`
- Verifica que "Clippy" aparezca en la lista
- Debe estar ANTES que "ClippyBridge"

### Problema: ClippyUI no conecta

```
[ClippyUI] ✗ Clippy autoload not found!
```

**Solución:**

- Verifica que Clippy esté en autoloads
- Reinicia el proyecto

### Problema: EventBus no emite señales

**Solución:**

- Verifica que el juego realmente esté emitiendo señales
- Añade debug en el código del juego:
  ```gdscript
  print("Emitting challenge_started")
  EventBus.challenge_started.emit(node)
  ```

### Problema: El texto no se genera

```
[ClippyController] Generated text: ...
```

**Si está vacío:**

- Verifica que los archivos de localización estén cargados
- Project Settings > Localization > Translations
- Añade `res://src/clippy/clippy_locales/en.po`
- Añade `res://src/clippy/clippy_locales/es.po`

### Problema: ClippyUI existe pero no se ve

**Solución:**

- Verifica que ClippyUI esté en **CanvasLayer** (layer 100)
- Revisa que el panel no esté fuera de pantalla
- En el editor, selecciona ClippyUI y verifica su posición

---

## 🎯 Checklist de Integración

- [ ] `project.godot` tiene autoloads Clippy y ClippyBridge
- [ ] Archivos .po en Project Settings > Localization
- [ ] ClippyUI.tscn añadido a MainMenu o Desktop scene
- [ ] Consola muestra mensajes de inicialización
- [ ] TestClippyEmitter añadido para pruebas
- [ ] Presionar teclas emite eventos y muestra mensajes

---

## 📞 Si Aún No Funciona

Envía el output completo de la consola cuando:

1. El juego inicia
2. Presionas 'T' en TestClippyEmitter
3. El juego ejecuta una acción que debería activar Clippy

Busca específicamente:

- Mensajes de error en rojo
- Dónde se detiene el flujo de mensajes de debug
- Si falta algún componente de los esperados

---

**Archivos Relacionados:**

- [ClippyController.gd](file:///c:/Users/Juanse/Documents/GitHub/juego-estructura-ii/src/clippy/ClippyController.gd)
- [ClippyEventBridge.gd](file:///c:/Users/Juanse/Documents/GitHub/juego-estructura-ii/src/clippy/ClippyEventBridge.gd)
- [ClippyUI.gd](file:///c:/Users/Juanse/Documents/GitHub/juego-estructura-ii/src/clippy/ClippyUI.gd)
- [TestClippyEmitter.gd](file:///c:/Users/Juanse/Documents/GitHub/juego-estructura-ii/src/clippy/TestClippyEmitter.gd)
- [project.godot](file:///c:/Users/Juanse/Documents/GitHub/juego-estructura-ii/project.godot)
