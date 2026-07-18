extends "res://world_element.gd"
class_name Interactable

@export var item_name: String = "Troca"

func _ready() -> void:
	super() 
	
	if Inventario.ja_foi_coletado(name):
		queue_free()
		return
		
	if not is_in_group("world_elements"):
		add_to_group("world_elements")
		
	# Garante que usa o mundo atual do player ao nascer
	var player = get_tree().get_first_node_in_group("player")
	if player and "current_world" in player:
		on_world_switched(player.current_world)
	else:
		on_world_switched(1) # Valor padrão de segurança

# Função que o jogador vai chamar ao apertar o botão de interagir
func interact() -> void:
	# 1. Tenta colocar o item no dicionário global
	var conseguiu_coletar = Inventario.adicionar_item(item_name)
	
	# 2. Se a função retornar TRUE (tinha espaço), aí sim o item some do chão!
	if conseguiu_coletar:
		print("Coletou o item ", item_name, " do chão com sucesso!")
		
		# Atualiza a interface do player na tela
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("atualizar_ui_inventario"):
			player.atualizar_ui_inventario()
			
		# Remove o item do mapa definitivamente
		queue_free()
	else:
		# Se retornar FALSE (inventário cheio), o item CONTINUA no chão intacto
		print("Seu bolso está lotado! O item permanecerá no chão.")
		# [Opcional] Som de erro do player:
		var player = get_tree().get_first_node_in_group("player")
		if player: player.som_bloqueio.play()

# [NOVO] Função para fazer o item sumir/aparecer na troca de dimensões
func on_world_switched(target_world: int) -> void:
	if target_world == active_in_world:
		show()
		# Ativa completamente as funções de detecção física da Area2D
		monitoring = true
		monitorable = true
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", false)
	else:
		hide()
		# Desativa completamente a Area2D para não criar paredes invisíveis nem ser detectada
		monitoring = false
		monitorable = false
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", true)
