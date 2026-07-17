extends Node2D

# Define em qual mundo este mapa deve ficar ativo (1 ou 2)
@export var active_in_world: int = 1

func _ready() -> void:
	# Entra no grupo que o personagem avisa ao trocar de mundo
	add_to_group("world_elements")
	# Configura o estado inicial do mapa
	update_map_state(1)


# Função chamada automaticamente pelo call_group do seu personagem
func on_world_switched(new_world: int) -> void:
	update_map_state(new_world)


func update_map_state(current_world: int) -> void:
	if current_world == active_in_world:
		show() # Mostra o mapa correspondente
		# Reativa as colisões físicas deste mapa (se houverem)
		process_mode = PROCESS_MODE_INHERIT 
	else:
		hide() # Esconde o outro mapa
		# Desativa completamente as colisões e scripts do mapa invisível
		process_mode = PROCESS_MODE_DISABLED
