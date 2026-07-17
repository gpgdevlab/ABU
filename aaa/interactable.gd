extends "res://world_element.gd"
class_name Interactable

@export var item_name: String = "Troca"
# Esta é a função que o jogador vai chamar ao apertar o botão de interagir
func interact() -> void:
	Inventario.adicionar_item(item_name)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Jogador encontrado no grupo! Atualizando UI...")
		if player.has_method("atualizar_ui_inventario"):
			player.atualizar_ui_inventario()
		else:
			print("ERRO: O script do player não tem a função atualizar_ui_inventario()!")
	else:
		print("ERRO: Nenhum nó foi encontrado no grupo 'player'!")
		
	queue_free()
