extends Node

## EventBus - Sistema centralizado de eventos
## Desacopla componentes del juego permitiendo comunicación mediante señales
@warning_ignore_start("unused_signal")
# Eventos de navegación
signal player_moved(node: TreeNode)
signal navigation_blocked(reason: String)
signal navigation_ready()  # Nueva señal cuando la navegación está lista

# Eventos de desafíos
signal challenge_started(node: TreeNode)
signal challenge_completed(node: TreeNode, win: bool)
signal challenge_state_changed(old_state: int, new_state: int)

# Eventos de juego
signal game_over(win: bool)
signal score_changed(old_score: int, new_score: int, reason: String)

# Eventos de visibilidad
signal node_visited(node: TreeNode)
signal node_discovered(node: TreeNode)

# Eventos de recursos
signal resources_loaded(success: bool)
signal app_database_ready(database: AppDatabase)
