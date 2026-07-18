extends Area2D # Mudamos aqui para estender direto de Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var item_dentro: String = "Troca"
@export var precisa_de_chave: bool = false
@export var nome_da_chave: String = "Chave do Bau"

# [NOVO] Adicionamos a variável que o sistema do seu mapa usa para saber em qual mundo o baú aparece
@export var active_in_world: int = 1 

var ja_aberto: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	if Inventario.ja_foi_coletado(name):
		ja_aberto = true
		animated_sprite.play("aberto")
	
	# Sincroniza o estado inicial do baú
	if active_in_world == 1:
		show()
		monitoring = true
		monitorable = true
		$CollisionShape2D.disabled = ja_aberto
	else:
		hide()
		monitoring = false
		monitorable = false
		$CollisionShape2D.disabled = true
		
func interact() -> void:
	# 1. Se já está aberto, não faz nada
	if ja_aberto:
		print("O baú já está vazio.")
		return
		
	# 2. Se precisa de chave, checa o inventário antes
	if precisa_de_chave and not Inventario.tem_item(nome_da_chave):
		print("Este baú está trancado! Você precisa de: ", nome_da_chave)
		return
		
	# 3. ABRE O BAÚ!
	ja_aberto = true
	animated_sprite.play("aberto")
	# [NOVO] Salva permanentemente no Singleton que ESTE baú específico foi aberto
	Inventario.registrar_coleta(name)
	
	if precisa_de_chave:
		Inventario.remover_item(nome_da_chave)
		
	# 4. Entrega o prêmio para o jogador
	Inventario.adicionar_item(item_dentro)
	print("Você abriu o baú e encontrou: ", item_dentro)
	
	# 5. Avisa o jogador para atualizar o texto do inventário na tela
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("atualizar_ui_inventario"):
		player.atualizar_ui_inventario()

# [NOVO] Função para fazer o baú sumir/aparecer quando trocar de mundo, igual aos seus outros itens
func on_world_switched(target_world: int) -> void:
	# Se o baú pertence a este mundo e ainda NÃO foi aberto
	if target_world == active_in_world:
		show()
		monitoring = true
		monitorable = true
		$CollisionShape2D.set_deferred("disabled", ja_aberto) 
	else:
		hide()
		# Desliga tudo para não criar blocos invisíveis nas outras dimensões
		monitoring = false
		monitorable = false
		$CollisionShape2D.set_deferred("disabled", true)
