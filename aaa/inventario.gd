extends Node

# Variáveis de controle de cena que já tínhamos
var posicao_retorno: Vector2 = Vector2.ZERO
var deve_posicionar_player: bool = false
var troca_desbloqueada: bool = false
var mundo_salvo: int = 1

# --- NOVO SISTEMA DE ARMAZENAMENTO ---
var itens: Dictionary = {
	"Troca": 0
}

# --- DEFINIÇÃO DE LIMITES MÁXIMOS ---
# Aqui ontrola o limite de cada item. Se criar um item novo, adicionar ele aqui!
var limites_maximos: Dictionary = {
	"Troca": 3,     
	"Chave": 5      
}

# Guarda o nome dos baús que já foram abertos (continua igual)
var baus_abertos: Array = []

func ja_foi_coletado(nome_bau: String) -> bool:
	return nome_bau in baus_abertos

func registrar_coleta(nome_bau: String) -> void:
	if not nome_bau in baus_abertos:
		baus_abertos.append(nome_bau)

# --- NOVA FUNÇÃO PARA ADICIONAR ITEM COM LIMITE ---
func adicionar_item(nome_do_item: String) -> bool:
	# 1. Se o item não existe no inventário ainda, inicializa ele com 0
	if not itens.has(nome_do_item):
		itens[nome_do_item] = 0
		
	# 2. Pega o limite configurado (se não achar o item na lista de limites, define como infinito/99)
	var limite_maximo = limites_maximos.get(nome_do_item, 99)
	
	# 3. Verifica se o jogador já atingiu o limite máximo daquele item
	if itens[nome_do_item] >= limite_maximo:
		print("Não foi possível coletar ", nome_do_item, "! Limite máximo atingido (", limite_maximo, ").")
		return false # Retorna FALSO para avisar que o inventário estava cheio!
		
	# 4. Se tiver espaço, adiciona +1 na quantidade
	itens[nome_do_item] += 1
	print("Item adicionado: ", nome_do_item, " (Total: ", itens[nome_do_item], "/", limite_maximo, ")")
	
	# Habilidade especial do botão Q (Sua lógica antiga)
	if nome_do_item == "Troca":
		troca_desbloqueada = true
		
	return true # Retorna VERDADEIRO avisando que coletou com sucesso

# --- FUNÇÃO PARA CHECAR SE TEM O ITEM ---
func tem_item(nome_do_item: String) -> bool:
	# Verifica se o item existe no dicionário e se a quantidade é maior que zero
	return itens.has(nome_do_item) and itens[nome_do_item] > 0

# --- FUNÇÃO PARA REMOVER/GASTAR ITEM ---
func remover_item(nome_do_item: String) -> void:
	if tem_item(nome_do_item):
		itens[nome_do_item] -= 1
		print("Item gasto: ", nome_do_item, " (Restam: ", itens[nome_do_item], ")")
