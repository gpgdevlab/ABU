extends Area2D

# Permite que você escolha qual sala essa porta vai abrir direto pelo Inspetor
@export_file("*.tscn") var cena_destino: String

# Controla em qual mundo essa porta fica visível
@export var active_in_world: int = 1

func _ready() -> void:
	# Sistema de grupos para sumir/aparecer nas dimensões
	add_to_group("world_elements")
	on_world_switched(1) # Começa checando o mundo inicial

func interact() -> void:
	if cena_destino == "":
		print("Erro: Nenhuma cena de destino configurada nesta porta!")
		return
		
	print("Entrando na sala...")
	
	# [NOVO] Se a cena de destino for o mundo principal, salvamos a nossa posição atual 
	# para o player saber onde nascer quando o mundo recarregar.
	if "mundo" in get_tree().current_scene.scene_file_path:
		Inventario.posicao_retorno = global_position + Vector2(0, 45)
		Inventario.deve_posicionar_player = true
		
		# [NOVO] Busca o jogador no grupo e salva o mundo em que ele estava
		var player = get_tree().get_first_node_in_group("player")
		if player and "current_world" in player:
			Inventario.mundo_salvo = player.current_world
			print("Mundo atual salvo na memória: Mundo ", Inventario.mundo_salvo)
		
		# 2. Guarda a posição de calçada apenas se estivermos no mapa principal
	if "mundo" in get_tree().current_scene.scene_file_path:
		Inventario.posicao_retorno = global_position + Vector2(0, 45)
		Inventario.deve_posicionar_player = true
	
	print("Trocando de cenário...")
	get_tree().change_scene_to_file(cena_destino)
	

# Controla a visibilidade nos mundos
func on_world_switched(target_world: int) -> void:
	if target_world == active_in_world:
		show()
		$CollisionShape2D.set_deferred("disabled", false)
	else:
		hide()
		$CollisionShape2D.set_deferred("disabled", true)
