# Clippy Assistant - Integration Guide

**Godot Version:** 4.5+  
**Language:** GDScript

## 📁 Directory Structure

```
src/clippy/
├── ClippyController.gd      # Main controller (state machine + API)
├── ClippyEvent.gd           # Event resource definition
├── ClippyResources.gd       # Documentation parser
├── resources/               # Example event resources
│   ├── tutorial_start.tres
│   ├── minigame_start.tres
│   ├── player_error.tres
│   ├── progress_update.tres
│   └── achievement.tres
└── clippy_locales/          # Localization files
    ├── en.po
    └── es.po

tests/clippy/
├── test_clippy_events.gd    # Event unit tests
└── test_clippy_controller.gd # Controller integration tests
```

## 🚀 Quick Start Integration

### Step 1: Add ClippyController to Scene Tree

**Option A: Autoload (Recommended)**

```
Project Settings > Autoload
  Script: res://src/clippy/ClippyController.gd
  Node Name: Clippy
```

**Option B: Manual Instance**

```gdscript
var clippy = ClippyController.new()
add_child(clippy)
```

### Step 2: Configure Localization

Add localization files in Project Settings:

```
Project Settings > Localization > Translations
  Add: res://src/clippy/clippy_locales/en.po
  Add: res://src/clippy/clippy_locales/es.po
```

### Step 3: Connect Signals

```gdscript
func _ready():
	# Connect to text display signal
	Clippy.ready_to_display.connect(_on_clippy_text_ready)

	# Optional: Connect to error signal
	Clippy.error_occurred.connect(_on_clippy_error)

func _on_clippy_text_ready(text: String):
	# Display text in UI (e.g., dialogue box, notification)
	print("Clippy says: ", text)
	# Example: show_dialogue_box(text)

func _on_clippy_error(error_msg: String):
	push_warning("Clippy error: ", error_msg)
```

## 📤 Emitting Events from Game Code

### Tutorial Start Event

```gdscript
var event = ClippyEvent.new()
event.event_type = ClippyEvent.EventType.TUTORIAL_START
event.level_id = "tutorial_area"
event.context_id = "tree_navigation_intro"
event.payload = {"section": "controls"}
Clippy.handle_event(event)
```

### Minigame Start Event

```gdscript
var event = ClippyEvent.new()
event.event_type = ClippyEvent.EventType.MINI_GAME_START
event.context_id = "port_scanner"
event.payload = {
	"game_type": "port_scanner",
	"difficulty": "normal"
}
Clippy.handle_event(event)
```

### Player Error Event

```gdscript
var event = ClippyEvent.new()
event.event_type = ClippyEvent.EventType.PLAYER_ERROR
event.payload = {
	"error_code": "wrong_answer",
	"attempt": 2
}
Clippy.handle_event(event)
```

### Progress Update Event

```gdscript
var event = ClippyEvent.new()
event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
event.payload = {
	"completion": 0.65,
	"nodes_visited": 8
}
Clippy.handle_event(event)
```

### Achievement Event

```gdscript
var event = ClippyEvent.new()
event.event_type = ClippyEvent.EventType.ACHIEVEMENT
event.context_id = "port_scanner_complete"
event.payload = {
	"achievement_name": "Port Scanner Master",
	"points_earned": 180
}
Clippy.handle_event(event)
```

## 🔌 Using EventBus Integration

If your game uses EventBus pattern (detected in project.godot):

```gdscript
# In EventBus.gd
signal tutorial_started(context_id: String)
signal minigame_started(game_type: String)
signal player_made_error(error_code: String, attempt: int)

# In clippy integration script
func _ready():
	EventBus.tutorial_started.connect(_on_tutorial_started)
	EventBus.minigame_started.connect(_on_minigame_started)
	EventBus.player_made_error.connect(_on_player_error)

func _on_tutorial_started(context_id: String):
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = context_id
	Clippy.handle_event(event)

func _on_minigame_started(game_type: String):
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.context_id = game_type
	event.payload = {"game_type": game_type}
	Clippy.handle_event(event)

func _on_player_error(error_code: String, attempt: int):
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PLAYER_ERROR
	event.payload = {"error_code": error_code, "attempt": attempt}
	Clippy.handle_event(event)
```

## 🎨 Creating Custom Event Types

### 1. Extend EventType Enum

Edit `ClippyEvent.gd`:

```gdscript
enum EventType {
	TUTORIAL_START,
	MINI_GAME_START,
	PLAYER_ERROR,
	PROGRESS_UPDATE,
	ACHIEVEMENT,
	TREE_NODE_ENTERED,
	HINT_REQUESTED,
	GAME_COMPLETED,
	CUSTOM_NEW_TYPE  # Add your custom type
}
```

### 2. Add Validation Logic

In `ClippyEvent.gd` > `is_valid()`:

```gdscript
EventType.CUSTOM_NEW_TYPE:
	return payload.has("required_field")
```

### 3. Add Text Generation Logic

In `ClippyResources.gd` > `get_text_for_event()`:

```gdscript
ClippyEvent.EventType.CUSTOM_NEW_TYPE:
	context_text = _get_custom_text(event)
```

Add helper function:

```gdscript
func _get_custom_text(event: ClippyEvent) -> String:
	return tr("CLIPPY_CUSTOM_MESSAGE")
```

### 4. Add Localization

In `en.po` and `es.po`:

```
msgid "CLIPPY_CUSTOM_MESSAGE"
msgstr "Your custom message here"
```

## 📊 Progress State API

```gdscript
# Get current state
var state = Clippy.get_progress_state()
print("Events processed: ", state.events_processed)
print("Errors: ", state.errors_count)
print("Last event type: ", state.last_event_type)
print("Display count: ", state.total_display_count)

# Reset progress
Clippy.reset()

# Clear event queue
Clippy.clear_queue()
```

## 📚 Extending Documentation Parser

### Adding New Minigame Documentation

```gdscript
# In your minigame initialization
Clippy._resources.load_minigame_doc(
	"my_new_minigame",
	"res://scenes/minigames/my_new_minigame/README.md"
)
```

### Structured README Format

For optimal parsing, structure your README with headers:

```markdown
## Objetivo

Description of objective...

## Controles

Control instructions...

## Consejos rápidos

- Tip 1
- Tip 2
```

Parser will extract sections automatically.

## 🧪 Running Tests

### Using GUT (Godot Unit Testing)

1. Install GUT addon: https://github.com/bitwes/Gut
2. Run from Godot Editor: `Scene > Run Gut Tests`
3. Or command line:

```bash
godot --path "c:/Users/Juanse/Documents/GitHub/juego-estructura-ii" --script addons/gut/gut_cmdln.gd -gdir=tests/clippy
```

### Manual Testing

Add test script to scene:

```gdscript
var test_events = preload("res://tests/clippy/test_clippy_events.gd").new()
add_child(test_events)

var test_controller = preload("res://tests/clippy/test_clippy_controller.gd").new()
add_child(test_controller)
```

## ⚠️ Important Notes

### Performance

- ClippyController auto-loads documentation on `_ready()`
- Disable with `clippy.auto_load_docs = false` for faster startup
- Call `clippy.load_project_docs(path)` manually when needed

### Event Queue

- Events are processed sequentially
- Controller auto-acknowledges after 0.1s
- Call `Clippy.acknowledge()` manually for custom timing

### State Machine

- States: IDLE, LISTENING, COMPOSING, WAITING_FOR_ACK, ERROR
- Listen to `state_changed` signal for debugging
- ERROR state auto-recovers to IDLE after 0.5s

### Localization

- Text generation uses `tr()` (TranslationServer)
- Game language changes reflect immediately
- Add translations to .po files, not code

## 🔧 Debugging

Enable debug output:

```gdscript
func _ready():
	Clippy.state_changed.connect(func(old, new):
		print("Clippy state: %s -> %s" % [old, new])
	)
	Clippy.error_occurred.connect(func(msg):
		print("Clippy error: ", msg)
	)
```

Check event validity:

```gdscript
var event = ClippyEvent.new()
# ... configure event ...
if not event.is_valid():
	print("Invalid event: ", event.get_description())
```

## 📝 Example Integration Script

Complete example (`ClippyIntegration.gd`):

```gdscript
extends Node

func _ready():
	# Connect signals
	Clippy.ready_to_display.connect(_show_clippy_message)

	# Example: Tutorial start
	var tutorial_event = ClippyEvent.new()
	tutorial_event.event_type = ClippyEvent.EventType.TUTORIAL_START
	tutorial_event.context_id = "game_intro"
	Clippy.handle_event(tutorial_event)

func _show_clippy_message(text: String):
	# Integrate with your UI system
	print("CLIPPY: ", text)
	# Example: $DialogueBox.show_text(text)
```

---

**System Version:** Godot 4.5+  
**Created for:** Safe TreeNet (RootPath Game)  
**License:** Match project license
