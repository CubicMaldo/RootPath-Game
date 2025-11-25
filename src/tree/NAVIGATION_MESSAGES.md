# 📍 Sistema de Mensajes de Navegación

## Descripción

Sistema que muestra mensajes contextuales cada vez que el jugador se mueve a un nuevo nodo en el árbol de navegación. Los mensajes revelan información sobre el nodo actual y proporcionan inmersión narrativa.

## 🎯 Características

### Mensajes por Tipo de Nodo

Cada tipo de nodo tiene un mensaje específico:

| Tipo de Nodo | Emoji | Nombre | Descripción |
|--------------|-------|--------|-------------|
| INICIO | 🏁 | Nodo de Inicio | Punto de partida de tu aventura |
| DESAFIO | ⚔️ | Nodo de Desafío | Has accedido a un desafío de ciberseguridad |
| PISTA | 💡 | Nodo de Pista | Nodo de ayuda con pistas disponibles |
| FINAL | 🎯 | Nodo Central Seguro | ¡Has llegado al objetivo final! |

### Mensajes Personalizados por Minijuego

Los nodos con minijuegos muestran nombres y descripciones específicas:

#### Password Cracker
- **Nombre**: "Servidor de Contraseñas"
- **Mensaje**: "Estás en el Servidor de Contraseñas. Sistema de autenticación detectado."

#### Network Defender
- **Nombre**: "Firewall Perimetral"
- **Mensaje**: "Estás en el Firewall Perimetral. Analizando tráfico de red."

#### Email Phishing Detector
- **Nombre**: "Servidor de Correo"
- **Mensaje**: "Has accedido al Servidor de Correo. Detecta amenazas de phishing."

#### Port Scanner Defender
- **Nombre**: "Sistema de Detección de Intrusos"
- **Mensaje**: "Estás en el Sistema de Detección de Intrusos. Vigilando puertos de red."

#### Password Strength Trainer
- **Nombre**: "Centro de Capacitación"
- **Mensaje**: "Has llegado al Centro de Capacitación. Aprende sobre contraseñas seguras."

#### SQL Injection Defender
- **Nombre**: "Base de Datos Principal"
- **Mensaje**: "Estás en la Base de Datos Principal. Protege contra inyecciones SQL."

## 🛠️ Implementación Técnica

### Archivos Modificados

```
scenes/tree/TreeApp.tscn
└── NavigationMessage (PanelContainer)
    └── VBoxContainer
        ├── NodeNameLabel (título del nodo)
        └── NodeDescriptionLabel (descripción)

assets/scripts/core/navigation/tree/interactions/TreeAppManager.gd
├── Diccionarios de mensajes
├── _show_node_message()
├── _get_custom_node_name()
├── _get_node_emoji()
└── _hide_navigation_message()
```

### Componentes UI

**NavigationMessage (PanelContainer)**
- Posición: Arriba del mapa de árbol
- Visibilidad: Oculto por defecto, se muestra al navegar
- Duración: 3 segundos (configurable)

**NodeNameLabel**
- Tamaño: 24px
- Formato: `[Emoji] [Nombre del Nodo]`
- Ejemplo: "⚔️ Servidor de Contraseñas"

**NodeDescriptionLabel**
- Tamaño: 18px
- Formato: Texto descriptivo contextual
- Auto-wrap: Habilitado

### Flujo de Ejecución

```
1. Jugador presiona botón de navegación (↓, ↑, ←, →)
2. PlayerNavigator emite señal "node_changed"
3. TreeAppController recibe la señal
4. _on_player_moved(node) se ejecuta
5. _show_node_message(node) se llama
6. Sistema determina nombre y descripción:
   - Busca si el nodo tiene app_resource
   - Si tiene, usa nombre/descripción personalizada
   - Si no, usa valores por defecto según tipo
7. Actualiza labels del mensaje
8. Muestra el PanelContainer (visible = true)
9. Inicia timer de 3 segundos
10. Timer expira → _hide_navigation_message()
11. Oculta el PanelContainer (visible = false)
```

### Funciones Clave

#### `_show_node_message(node: TreeNode)`
Muestra el mensaje de navegación para un nodo específico.

**Lógica:**
1. Verifica que el nodo y UI existan
2. Obtiene nombre base del tipo de nodo
3. Si tiene app_resource, obtiene nombre personalizado
4. Obtiene descripción (personalizada si tiene app)
5. Obtiene emoji según tipo
6. Actualiza labels
7. Muestra panel
8. Inicia timer

#### `_get_custom_node_name(node: TreeNode) -> String`
Retorna el nombre personalizado de un nodo basado en su app.

**Mapeo:**
```gdscript
"password cracker" → "Servidor de Contraseñas"
"network defender" → "Firewall Perimetral"
"email phishing detector" → "Servidor de Correo"
"port scanner defender" → "Sistema de Detección de Intrusos"
"entrenador de contraseñas" → "Centro de Capacitación"
"sql injection defender" → "Base de Datos Principal"
```

#### `_get_node_emoji(tipo: int) -> String`
Retorna el emoji correspondiente al tipo de nodo.

**Mapeo:**
```gdscript
INICIO → "🏁"
DESAFIO → "⚔️"
PISTA → "💡"
FINAL → "🎯"
default → "📍"
```

#### `_hide_navigation_message()`
Oculta el mensaje de navegación después del timeout.

### Timer Configuration

```gdscript
message_timer = Timer.new()
message_timer.one_shot = true
message_timer.wait_time = 3.0  # 3 segundos
message_timer.timeout.connect(_hide_navigation_message)
```

## 📊 Diccionarios de Datos

### node_names
```gdscript
{
	TreeNode.NodosJuego.INICIO: "Nodo de Inicio",
	TreeNode.NodosJuego.DESAFIO: "Nodo de Desafío",
	TreeNode.NodosJuego.PISTA: "Nodo de Pista",
	TreeNode.NodosJuego.FINAL: "Nodo Central Seguro"
}
```

### node_descriptions
```gdscript
{
	TreeNode.NodosJuego.INICIO: "Punto de partida de tu aventura.",
	TreeNode.NodosJuego.DESAFIO: "Has accedido a un desafío de ciberseguridad.",
	TreeNode.NodosJuego.PISTA: "Nodo de ayuda con pistas disponibles.",
	TreeNode.NodosJuego.FINAL: "¡Has llegado al objetivo final!"
}
```

### app_descriptions
```gdscript
{
	"password cracker": "Estás en el Servidor de Contraseñas...",
	"network defender": "Estás en el Firewall Perimetral...",
	"email phishing detector": "Has accedido al Servidor de Correo...",
	...
}
```

## 🎨 Diseño Visual

### Ejemplo de Mensaje

```
┌────────────────────────────────────────────┐
│  ⚔️ Servidor de Contraseñas                │
│  Estás en el Servidor de Contraseñas.     │
│  Sistema de autenticación detectado.       │
└────────────────────────────────────────────┘
```

### Estilos Aplicados

- **Panel**: Fondo oscuro semitransparente (0.1, 0.1, 0.1, 0.6)
- **Bordes**: Redondeados (3px)
- **Padding**: 20px en todos los lados
- **Alineación**: Centrada horizontalmente
- **Auto-wrap**: Habilitado para texto largo

## 🔧 Configuración

### Cambiar Duración del Mensaje

```gdscript
# En _setup_message_timer()
message_timer.wait_time = 5.0  # Cambiar a 5 segundos
```

### Agregar Nuevo Minijuego

1. Agregar entrada a `_get_custom_node_name()`:
```gdscript
"nombre_del_minijuego":
	return "Nombre Descriptivo"
```

2. Agregar entrada a `app_descriptions`:
```gdscript
"nombre_del_minijuego": "Mensaje descriptivo al acceder."
```

### Personalizar Emojis

Modificar `_get_node_emoji()`:
```gdscript
TreeNode.NodosJuego.DESAFIO:
	return "🎮"  # Cambiar emoji
```

## 📝 Ejemplos de Uso

### Ejemplo 1: Navegación a Nodo Inicial
```
Usuario: Inicia el juego
Sistema: Muestra "🏁 Nodo de Inicio"
         "Punto de partida de tu aventura."
```

### Ejemplo 2: Navegación a Minijuego
```
Usuario: Navega al nodo de Password Cracker
Sistema: Muestra "⚔️ Servidor de Contraseñas"
         "Estás en el Servidor de Contraseñas. 
         Sistema de autenticación detectado."
```

### Ejemplo 3: Navegación al Nodo Final
```
Usuario: Llega al nodo central
Sistema: Muestra "🎯 Nodo Central Seguro"
         "¡Has llegado al objetivo final! 
         Completa el último desafío."
```

## 🚀 Mejoras Futuras

### Posibles Extensiones

1. **Sonidos de Navegación**
   - Reproducir efecto de sonido al mostrar mensaje
   - Diferentes sonidos por tipo de nodo

2. **Animaciones de Entrada/Salida**
   - Fade in/out
   - Slide desde arriba
   - Scale animation

3. **Mensajes Contextuales**
   - Diferentes mensajes si el nodo ya fue visitado
   - Mencionar nodos completados
   - Hints sobre próximos desafíos

4. **Historial de Navegación**
   - Mostrar ruta seguida
   - "Has explorado X nodos"
   - "Te quedan Y desafíos"

5. **Mensajes Dinámicos**
   - Basados en el progreso del jugador
   - Según el tiempo transcurrido
   - Según desafíos completados

6. **Localización**
   - Soporte multi-idioma
   - Mensajes en español/inglés

---

**Implementado**: Sistema de Mensajes de Navegación v1.0  
**Fecha**: 2025  
**Proyecto**: Aventura Cibernética - Estructuras de Datos II
