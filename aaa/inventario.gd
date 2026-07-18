extends Node

# Lista simples para guardar os nomes dos itens coletados
var itens: Array[String] = []
var itens_coletados: Array = []

# Guardar posisão de retorno
var posicao_retorno: Vector2 = Vector2.ZERO
var deve_posicionar_player: bool = false

# Guardar mundo atual
var mundo_salvo: int = 1

# Desbloquear troca
var troca_desbloqueada: bool = false

# Função para adicionar um item
func adicionar_item(nome_do_item: String) -> void:
	itens.append(nome_do_item)

	# [NOVO] Se o item coletado for a "Troca", desbloqueia o botão Q para sempre
	if nome_do_item == "Troca":
		troca_desbloqueada = true
		print("Habilidade de troca de mundos DESBLOQUEADA permanentemente!")
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

func registrar_coleta(id_do_objeto: String) -> void:
	if not itens_coletados.has(id_do_objeto):
		itens_coletados.append(id_do_objeto)

func ja_foi_coletado(id_do_objeto: String) -> bool:
	return itens_coletados.has(id_do_objeto)
