extends Area2D # Ou Node2D, dependendo do tipo do objeto

# Define em qual mundo este objeto deve aparecer (Mundo 1 ou Mundo 2)
@export var active_in_world: int = 1

func _ready() -> void:
	# Adiciona este objeto ao grupo para que o personagem consiga avisá-lo quando o mundo mudar
	add_to_group("world_elements")
	# Atualiza o estado inicial do objeto logo que o jogo começa
	update_presence(1) 
	
# Esta função será chamada pelo get_tree().call_group() do seu personagem
func on_world_switched(new_world: int) -> void:
	update_presence(new_world)

func update_presence(current_world: int) -> void:
	if current_world == active_in_world:
		show() # Torna o objeto visível
		# Se for uma Area2D, reativa as colisões para o jogador conseguir interagir
		monitorable = true 
	else:
		hide() # Esconde o objeto
		monitorable = false # Desativa as colisões para não interagir invisível
