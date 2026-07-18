extends Area2D # Estender direto de Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var item_dentro: String = "Troca"
@export var precisa_de_chave: bool = false
@export var nome_da_chave: String = "Chave do Bau"

# A variável que o sistema do mapa usa para saber em qual mundo o baú aparece
@export var active_in_world: int = 1 

var ja_aberto: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	# 1. Se o inventário global disser que este baú já foi aberto antes:
	if Inventario.ja_foi_coletado(name):
		ja_aberto = true
		
		# [Ajuste Visual] Coloca a animação no modo "aberto"
		animated_sprite.animation = "aberto"
		
		# Força o sprite a ir direto para o último frame 
		# e para a reprodução imediatamente para não rodar a animação de novo
		var ultimo_frame = animated_sprite.sprite_frames.get_frame_count("aberto") - 1
		animated_sprite.set_frame_and_progress(ultimo_frame, 0.0)
		animated_sprite.stop()
	
	# 2. Sincroniza o estado inicial das colisões e visibilidade (continua igual)
	if active_in_world == 1:
		show()
		monitoring = true
		monitorable = true
		$CollisionShape2D.disabled = ja_aberto # Desativa a área se já foi aberto
		
		# [CORREÇÃO] O StaticBody2D DEVE continuar ATIVO (false para disabled) 
		# mesmo se o baú já foi aberto, contanto que seja o mundo correto!
		if has_node("StaticBody2D/CollisionShape2D"):
			$"StaticBody2D/CollisionShape2D".disabled = false
	else:
		hide()
		monitoring = false
		monitorable = false
		$CollisionShape2D.disabled = true
		
		# [NOVO] Desativa a parede física completamente se for do outro mundo
		if has_node("StaticBody2D/CollisionShape2D"):
			$"StaticBody2D/CollisionShape2D".disabled = true
		
func interact() -> void:
	# 1. Se já está aberto, não faz nada
	if ja_aberto:
		print("O baú já está vazio.")
		return
		
	# 2. Se precisa de chave, checa o inventário antes
	if precisa_de_chave:
			Inventario.remover_item(nome_da_chave)
			print("Chave ", nome_da_chave, " utilizada e removida do inventário.")
		
	var conseguiu_coletar = Inventario.adicionar_item(item_dentro)
	
	if conseguiu_coletar:
		# Se tinha espaço no inventário, o baú abre normalmente!
		ja_aberto = true
		Inventario.registrar_coleta(name)
		animated_sprite.play("aberto")
		
		# Desativa APENAS a Area2D (para o jogador não conseguir apertar "E" de novo)
		$CollisionShape2D.disabled = true
			
		# Código para atualizar o player
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("atualizar_ui_inventario"):
			player.atualizar_ui_inventario()
	else:
		# Se retornou false, significa que o limite foi estourado!
		print("O baú não pode ser aberto porque seu bolso está cheio deste item!")
		var player = get_tree().get_first_node_in_group("player")
		if player: player.som_bloqueio.play()

# Função para fazer o baú sumir/aparecer quando trocar de mundo, igual aos seus outros itens
func on_world_switched(target_world: int) -> void:
	if target_world == active_in_world:
		show()
		monitoring = not ja_aberto
		monitorable = not ja_aberto
		$CollisionShape2D.set_deferred("disabled", ja_aberto) 
		
		# [NOVO] Se voltou para o mundo do baú, liga a parede física dele novamente
		if has_node("StaticBody2D/CollisionShape2D"):
			$"StaticBody2D/CollisionShape2D".set_deferred("disabled", false)
	else:
		hide()
		monitoring = false
		monitorable = false
		$CollisionShape2D.set_deferred("disabled", true)
		
		# [NOVO] Se mudou de mundo, desliga a parede física para o jogador passar por cima
		if has_node("StaticBody2D/CollisionShape2D"):
			$"StaticBody2D/CollisionShape2D".set_deferred("disabled", true)
