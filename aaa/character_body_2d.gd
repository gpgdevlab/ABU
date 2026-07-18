extends CharacterBody2D

# --- VARIÁVEIS DE MOVIMENTO ---
@export var speed: float = 200.0
@onready var texto_inventario: Label = $CanvasLayer/TextoInventario
@export var dash_speed: float = 600.0   # Velocidade durante o dash (o triplo da normal)
@export var dash_duration: float = 0.15 # Quanto tempo dura o "sumiço" (em segundos)
@export var dash_cooldown: float = 0.6 # Tempo de espera para poder usar de novo
	
var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.DOWN
var tempo_ultimo_clique: float = 0.0

# --- CARREGAR OS FRAME DE CADA MUNDO ---
var frames_mundo_1 = preload("res://nootnoot/frames_mundo1.tres")
var frames_mundo_2 = preload("res://nootnoot/frames_mundo2.tres")

# --- REFERÊNCIA DA ANIMAÇÃO ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- REFERÊNCIA DA TELAPRETA ---
@onready var tela_preta: ColorRect = $CanvasLayer/TelaPreta

# --- REFERÊNCIA DE CÂMERA ---
@onready var camera: Camera2D = $Camera2D

# --- REFERÊNCIA DOS ÁUDIOS ---
@onready var musica_mundo_1: AudioStreamPlayer2D = $MusicaMundo1
@onready var musica_mundo_2: AudioStreamPlayer2D = $MusicaMundo2
@onready var som_troca_mundo: AudioStreamPlayer2D = $SomTrocaMundo
@onready var som_bloqueio: AudioStreamPlayer2D = $SomBloqueio

# --- REFERÊNCIA DO SISTEMA ---
@onready var menu_pausa: ColorRect = $CanvasLayer/MenuPausa

# --- SISTEMA DE MUNDOS ---
var current_world: int = 1

# --- SISTEMA DE INTERAÇÃO ---
var interactable_object = null

func _physics_process(_delta: float) -> void:
	# 0. Se estiver dando o dash, move na direção travada e ignora os comandos normais
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return
	
	# 1. Movimentação Topdown básica
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		dash_direction = direction.normalized()
		
		# [VERIFICAÇÃO DE SPAM] Sempre que uma tecla é pressionada, atualiza o cronômetro do jogo
		tempo_ultimo_clique = Time.get_ticks_msec() / 1000.0
		
		# 2. SISTEMA DE ANIMAÇÃO PROTEGIDO CONTRA REINICIALIZAÇÃO
		var animacao_desejada = ""
		if abs(direction.x) > abs(direction.y):
			animacao_desejada = "move_right" if direction.x > 0 else "move_left"
		else:
			animacao_desejada = "move_down" if direction.y > 0 else "move_up"
			
		if animated_sprite.animation != animacao_desejada or not animated_sprite.is_playing():
			animated_sprite.play(animacao_desejada)
				
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		# Calcula quanto tempo se passou desde o último clique de movimento
		var tempo_desde_o_clique = (Time.get_ticks_msec() / 1000.0) - tempo_ultimo_clique
		
		# [TRAVA DE SPAM] Se o último clique aconteceu há menos de 0.15 segundos,
		# o jogo considera que você está "spamando" a tecla e NÃO para a animação!
		if tempo_desde_o_clique < 0.15:
			# Mantém a animação rodando normalmente enquanto o spam durar
			if not animated_sprite.is_playing():
				animated_sprite.play()
		else:
			# Se você realmente soltou o botão e parou de spamar, aí sim reseta o frame
			if velocity.length() < 10.0:
				animated_sprite.stop()
				animated_sprite.frame = 0

	move_and_slide()

func _ready() -> void:
	# 1. Se viemos de uma porta que salvou a posição, aplica apenas no mundo de fora
	if Inventario.deve_posicionar_player and "mundo" in get_tree().current_scene.scene_file_path:
		global_position = Inventario.posicao_retorno
		Inventario.deve_posicionar_player = false
	
	# [CORREÇÃO] Restaura o mundo salvo para o personagem manter a skin correta dentro de QUALQUER sala
	current_world = Inventario.mundo_salvo
	print("Player carregado na sala atual usando o Mundo: ", current_world)
		
	# 2. Atualiza os visuais e frames do cowboy para o mundo restaurado
	if current_world == 1:
		animated_sprite.sprite_frames = frames_mundo_1
	else:
		animated_sprite.sprite_frames = frames_mundo_2
		
	# [NOVO] 3. Força o personagem a nascer olhando para frente (para baixo)
	# Se ele estiver voltando para o mundo de fora, ajustamos a pose inicial
	if "mundo" in get_tree().current_scene.scene_file_path:
		animated_sprite.play("move_down") # Seleciona a animação de andar/olhar para baixo
		animated_sprite.stop()            # Pausa a animação imediatamente
		animated_sprite.frame = 0         # Trava no primeiro frame (ele em pé parado)
		print("Pose inicial definida: Olhando para baixo")

	# 4. Força todos os elementos dessa sala a respeitarem o mundo
	get_tree().call_group("world_elements", "on_world_switched", current_world)
		
	atualizar_ui_inventario()
	atualizar_musica_do_mundo()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		alternar_pausa()
	
	# 1. Detecta o comando de interagir
	if event.is_action_pressed("interact"):
		try_to_interact()
		
	# 2. Detecta o comando de trocar de mundo
	if event.is_action_pressed("switch_world"):
		toggle_world()
		
	# 3. ALTERNAR INVENTÁRIO (Aperta uma vez abre, aperta de novo fecha)
	if event.is_action_pressed("show_inventory"):
		if texto_inventario.visible:
			texto_inventario.hide() # Se já estava na tela, esconde
		else:
			atualizar_ui_inventario() # Atualiza os itens antes de mostrar
			texto_inventario.show()   # Se estava escondido, mostraasd
# [NOVO] 4. Detecta o comando de Dash 
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("dash"): 
		executar_dash()


# --- FUNÇÕES AUXILIARES ---

# Função para tentar interagir com algo próximo
func try_to_interact() -> void:
	# 1. Verifica se o nó de interação existe antes de pedir as áreas
	if not has_node("InteractionZone"):
		print("Erro: O nó InteractionZone não foi encontrado no personagem!")
		return
		
	var areas_perto = $InteractionZone.get_overlapping_areas()
	var interagiu = false
	
	for area in areas_perto:
		# 2. [PROTEÇÃO] Verifica se a área existe e não é nula (Nil)
		if area == null:
			continue
			
		# 3. Se a área for válida e tiver a função de interagir, executa-a
		if area.has_method("interact"):
			area.interact()
			interagiu = true
			break # Para o loop no primeiro objeto que interagir
			
	if not interagiu:
		print("Nada para interagir por perto.")


# --- FUNÇÃO DE TRANSIÇÃO DE MUNDO ---
func toggle_world() -> void:
	# [NOVO] 1. Bloqueia o botão Q se ele nunca tiver coletado o item de troca
	if not Inventario.troca_desbloqueada:
		print("Botão Q bloqueado: Você ainda não encontrou o item de Troca!")
		return # Cancela o código aqui mesmo, sem gastar nada e sem piscar a tela
	# [NOVO] 2. Checa se o jogador tem o item necessário para viajar
	if not Inventario.tem_item("Troca"):
		print("Você não tem nenhuma carga de 'Troca' para mudar de dimensão!")
		$SomBloqueio.play()
		# [NOVO] Chacoalha a câmera! Intensidade de 8 pixels por 0.25 segundos
		tremer_camera(8.0, 0.25)
		piscar_tela_bloqueio() # Dá o mesmo feedback visual se ele não tiver o item
		return # Cancela a viagem aqui mesmo
		
	# 3. Define qual seria o próximo mundo
	var next_world = 2 if current_world == 1 else 1
	
	# 4. Ativa temporariamente o próximo mundo para a física testar
	get_tree().call_group("world_elements", "on_world_switched", next_world)
	
	# 5. Espera a física processar o estado das paredes
	await get_tree().physics_frame
	
	# 6. Testa se o jogador ficaria preso no lugar
	if test_move(global_transform, Vector2.ZERO):
		print("Bloqueado! Há um obstáculo na outra dimensão.")
		# Se deu ruim, força todo mundo a voltar para o mundo atual
		get_tree().call_group("world_elements", "on_world_switched", current_world)
		$SomBloqueio.play() # Toca o som de bloqueio
		# [NOVO] Chacoalha a câmera! Intensidade de 8 pixels por 0.25 segundos
		tremer_camera(8.0, 0.25)
		piscar_tela_bloqueio()
		return # Cancela a troca e NÃO consome o item!
		
	# 7. SE CHEGOU AQUI, O CAMINHO ESTÁ LIVRE E VOCÊ TEM O ITEM! Confirma a troca definitiva
	current_world = next_world
	if current_world == 1:
		animated_sprite.sprite_frames = frames_mundo_1
	else:
		animated_sprite.sprite_frames = frames_mundo_2
		
	# [NOVO] 8. Consome o item do inventário apenas agora que a troca deu 100% certo!
	Inventario.remover_item("Troca")
	atualizar_ui_inventario() # Atualiza o texto da tela para sumir com o item gasto
	som_troca_mundo.play() # Toca o audio de troca
	# [NOVO] Chacoalha a câmera! Intensidade de 8 pixels por 0.25 segundos
	tremer_camera(8.0, 0.25)
	# 9. Força o mapa a se atualizar definitivamente para o novo mundo
	get_tree().call_group("world_elements", "on_world_switched", current_world)
	
	# 10qqqqqqqqqqqqqqqq. Atualiza o visual do cowboy
	change_world_visuals(Color(1.0, 1.0, 1.0))
	atualizar_musica_do_mundo()
# Apenas um efeito visual simples de demonstração no jogador
func change_world_visuals(new_color: Color) -> void:
	modulate = new_color
	
func _on_interaction_zone_area_entered(area: Area2D) -> void:
	print("Encontrei alguma área! Nome: ", area.name)
	
	# Verifica diretamente se o objeto colidido é do tipo Interactable
	if area is Interactable:
		print("E ela é um objeto interativo válido!")
		interactable_object = area

func _on_interaction_zone_area_exited(area: Area2D) -> void:
	# Se a área que saiu for o nosso objeto atual, limpa a referência
	if area == interactable_object:
		interactable_object = null
		
func atualizar_ui_inventario() -> void:
	var texto_final = "Inventario: "
	var tem_itens = false
	
	# Passa por todos os itens do dicionário para montar o texto da interface
	for nome_item in Inventario.itens:
		var quantidade = Inventario.itens[nome_item]
		
		# Só mostra na tela se o jogador tiver pelo menos 1 unidade do item
		if quantidade > 0:
			tem_itens = true
			var limite = Inventario.limites_maximos.get(nome_item, 99)
			texto_final += nome_item + " (" + str(quantidade) + "/" + str(limite) + ") "
			
	if not tem_itens:
		texto_inventario.text = "Inventario: Vazio"
	else:
		texto_inventario.text = texto_final

func piscar_tela_bloqueio() -> void:
	# Garante que o nó está visível antes de começar a animação
	tela_preta.show()
	
	# Zera a opacidade inicial para começar do zero absoluto
	tela_preta.modulate.a = 0.0
	
	var tween = create_tween()
	
	# 1. Escurece a tela até 60% de opacidade preta em 0.1 segundos
	tween.tween_property(tela_preta, "modulate:a", 0.6, 0.1)
	
	# 2. Volta a ficar totalmente transparente em 0.15 segundos
	tween.tween_property(tela_preta, "modulate:a", 0.0, 0.15)
	
	# 3. Quando a animação terminar por completo, esconde o nó para poupar processamento
	tween.tween_callback(func(): tela_preta.hide())

func atualizar_musica_do_mundo() -> void:
	if current_world == 1:
		# Se a música 1 não estiver tocando, dá o play
		if not musica_mundo_1.playing:
			musica_mundo_1.play()
		# Para a música do mundo 2
		musica_mundo_2.stop()
	else:
		# Se a música 2 não estiver tocando, dá o play
		if not musica_mundo_2.playing:
			musica_mundo_2.play()
		# Para a música do mundo 1
		musica_mundo_1.stop()
	
func tremer_camera(intensidade: float, duracao: float) -> void:
	var tween = create_tween()
	
	# Faz a câmera dar pequenos solavancos rápidos mudando o offset
	# Vamos fazer 4 movimentos rápidos aleatórios para simular o tremor
	for i in range(4):
		var direcao_aleatoria = Vector2(
			randf_range(-intensidade, intensidade),
			randf_range(-intensidade, intensidade)
		)
		# Move para a posição tremida
		tween.tween_property(camera, "offset", direcao_aleatoria, duracao / 5.0)
		
	# No final, força a câmera a voltar exatamente para o centro suavemente
	tween.tween_property(camera, "offset", Vector2.ZERO, duracao / 5.0)
	
func executar_dash() -> void:
	if not can_dash or is_dashing:
		return
		
	is_dashing = true
	can_dash = false
	
	# Efeito visual de "sumir": deixa o sprite invisível ou quase invisível (opacidade baixa)
	animated_sprite.modulate.a = 0.1 # 0.1 se quiser rastro fantasma
	
	# Treme a tela de leve no dash
	tremer_camera(3.0, 0.1)
	
	# Espera o tempo de duração do dash terminar
	await get_tree().create_timer(dash_duration).timeout
	
	# Termina o movimento do dash e faz o personagem reaparecer
	is_dashing = false
	animated_sprite.modulate.a = 1.0 # Volta a opacidade normal
	
	# Espera o tempo de recarga para liberar o botão novamente
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
	print("Dash pronto para usar novamente!")
	
func alternar_pausa() -> void:
	get_tree().paused = not get_tree().paused
	menu_pausa.visible = get_tree().paused
	
	# [NOVO] Se o jogo foi despausado, tira totalmente o foco do menu
	if not get_tree().paused:
		menu_pausa.release_focus()
	print("Estado de pausa: ", get_tree().paused)


func _on_botao_voltar_pressed() -> void:
	# Se clicou em voltar, apenas despausa e esconde o menu
	alternar_pausa()

func _on_botao_sair_pressed() -> void:
	# Despausa o motor antes de sair para não congelar o motor do editor
	get_tree().paused = false
	# Fecha o jogo completamente
	get_tree().quit()
