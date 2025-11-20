# Clippy Integration Instructions

## 🚀 Quick Setup (3 Steps)

### Step 1: Add Autoloads

Open **Project Settings > Autoload** and add (in this order):

```
1. EventBus (already exists) - res://assets/scripts/core/EventBus.gd
2. Clippy - res://src/clippy/ClippyController.gd
3. ClippyBridge - res://src/clippy/ClippyEventBridge.gd
```

### Step 2: Add Localization

**Project Settings > Localization > Translations:**

- Add: `res://src/clippy/clippy_locales/en.po`
- Add: `res://src/clippy/clippy_locales/es.po`

### Step 3: Add UI to Game Scene

Open `principalGameScene.tscn` (or your main game scene) and:

1. Add Child Node > CanvasLayer
2. Attach Scene: `res://src/clippy/ClippyUI.tscn`

**Done!** Clippy will now automatically respond to game events.

---

## 🎯 How It Works

```
Game Code
    ↓
EventBus.challenge_started.emit(node)
    ↓
ClippyBridge (subscribed to EventBus)
    ↓
Converts to ClippyEvent
    ↓
ClippyController.handle_event(event)
    ↓
Generates text from docs/templates
    ↓
Emits ready_to_display signal
    ↓
ClippyUI displays message
```

---

## 📡 Supported Events (Automatic)

| EventBus Signal              | ClippyEvent Type  | When Triggered              |
| ---------------------------- | ----------------- | --------------------------- |
| `navigation_ready`           | TUTORIAL_START    | Game navigation initialized |
| `player_moved`               | TREE_NODE_ENTERED | Player navigates to node    |
| `challenge_started`          | MINI_GAME_START   | Minigame begins             |
| `challenge_completed` (win)  | ACHIEVEMENT       | Challenge won               |
| `challenge_completed` (lose) | PLAYER_ERROR      | Challenge failed            |
| `game_over` (win)            | GAME_COMPLETED    | Victory                     |
| `score_changed`              | PROGRESS_UPDATE   | Score increases             |
| `navigation_blocked`         | PLAYER_ERROR      | Invalid move                |

**No additional code needed** - ClippyBridge handles all conversions!

---

## 🔧 Manual Event Emission (Optional)

If you need to trigger Clippy from custom code:

```gdscript
# Direct approach
var event = ClippyEvent.new()
event.event_type = ClippyEvent.EventType.HINT_REQUESTED
Clippy.handle_event(event)

# Or emit via EventBus (recommended)
# Add custom signal to EventBus.gd first
EventBus.hint_requested.emit()
# Then handle in ClippyBridge
```

---

## 🎨 UI Customization

Edit `ClippyUI.tscn` or override in Inspector:

- `auto_dismiss_time`: 8.0 (seconds) - Set to 0 to disable
- `show_icon`: true/false - Show character icon
- `animation_duration`: 0.3 (seconds)

Styling in `ClippyUI.tscn` > ClippyPanel > StyleBoxFlat:

- `bg_color`: Background color
- `border_color`: Border color
- `corner_radius`: Rounded corners

---

## 🧪 Testing

1. Run game
2. Start playing - watch console for ClippyBridge messages
3. Navigate tree - should trigger tutorial/navigation messages
4. Start minigame - should show minigame intro
5. Complete challenge - should show achievement message

**Debug mode:**

```gdscript
# In ClippyBridge._ready(), enable debug:
print("[ClippyBridge] Event: ", event.get_description())
```

---

## 📝 Adding Custom Localizations

Edit `src/clippy/clippy_locales/es.po` or `en.po`:

```po
msgid "CLIPPY_CUSTOM_MESSAGE"
msgstr "Tu mensaje personalizado aquí"
```

Then use in code:

```gdscript
var text = tr("CLIPPY_CUSTOM_MESSAGE")
```

---

## ⚠️ Troubleshooting

**Messages not appearing?**

- Check ClippyUI is in scene tree
- Verify autoloads are in correct order
- Check console for "[ClippyBridge] Connected" message

**Wrong language?**

- Project Settings > Internationalization > Locale
- Set to "en" or "es"

**Events not triggering?**

- Verify EventBus signals exist (check EventBus.gd)
- Check game code emits signals correctly
- Enable debug mode in ClippyBridge

---

**Files Modified:** 0 (all integration is additive!)  
**Autoloads Added:** 2 (Clippy, ClippyBridge)  
**Scenes Modified:** 1 (add ClippyUI.tscn)
