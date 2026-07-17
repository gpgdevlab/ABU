extends Node

# lista simples para guardar os nomes dos itens coletados
var itens: Array[String] = []

# Função para adicionar um item
func adicionar_item(nome_do_item: String) -> void:
	itens.append(nome_do_item)
	print("Item adicionado ao inventário: ", nome_do_item)
	print("Inventário atual: ", itens)

# Função para verificar se o jogador tem um item específico 
func tem_item(nome_do_item: String) -> bool:
	return itens.has(nome_do_item)

# Função para remover um item 
func remover_item(nome_do_item: String) -> void:
	# O "if" agora consome o valor (true/false) que o tem_item() devolve!
	if tem_item(nome_do_item):
		itens.erase(nome_do_item)
		print("Item removido do inventário: ", nome_do_item)
