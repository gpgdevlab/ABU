extends CharacterBody2D

# --- VARIÁVEIS DE MOVIMENTO ---
@export var speed: float = 200.0
@onready var texto_inventario: Label = $CanvasLayer/TextoInventario
# --- CARREGAR OS FRAME DE CADA MUNDO ---
var frames_mundo_1 = preload("res://nootnoot/frames_mundo1.tres")
var frames_mundo_2 = preload("res://nootnoot/frames_mundo2.tres")

# --- REFERÊNCIA DA ANIMAÇÃO ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- REFERÊNCIA DA TELAPRETA ---
@onready var tela_preta: ColorRect = $CanvasLayer/TelaPreta

# --- SISTEMA DE MUNDOS ---
var current_world: int = 1

# --- SISTEMA DE INTERAÇÃO ---
var interactable_object = null

func _physics_process(_delta: float) -> void:
	# 1. Movimentação Topdown básica
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		
		# 2. SISTEMA DE ANIMAÇÃO BASEADO NA DIREÇÃO
		# Prioriza a direção com maior força no movimento
		if abs(direction.x) > abs(direction.y):
			# Movimento horizontal
			if direction.x > 0:
				animated_sprite.play("move_right")
			else:
				animated_sprite.play("move_left")
		else:
			# Movimento vertical
			if direction.y > 0:
				animated_sprite.play("move_down")
			else:
				animated_sprite.play("move_up")
				
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		# 3. PARADO (IDLE)
		# Quando o jogador para, manter o frame parado olhando para a última direção,
		# ou simplesmente parar a animação atual no primeiro quadro (frame 0)
		animated_sprite.stop()
		animated_sprite.frame = 0 # Mantém o sprite de pé, sem caminhar

	move_and_slide()

func _ready() -> void:
	atualizar_ui_inventario()


func _unhandled_input(event: InputEvent) -> void:
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
	# [NOVO] 1. Checa se o jogador tem o item necessário para viajar
	if not Inventario.tem_item("Troca"):
		print("Você não tem nenhuma carga de 'Troca' para mudar de dimensão!")
		piscar_tela_bloqueio() # Dá o mesmo feedback visual se ele não tiver o item
		return # Cancela a viagem aqui mesmo
		
	# 2. Define qual seria o próximo mundo
	var next_world = 2 if current_world == 1 else 1
	
	# 3. Ativa temporariamente o próximo mundo para a física testar
	get_tree().call_group("world_elements", "on_world_switched", next_world)
	
	# 4. Espera a física processar o estado das paredes
	await get_tree().physics_frame
	
	# 5. Testa se o jogador ficaria preso no lugar
	if test_move(global_transform, Vector2.ZERO):
		print("Bloqueado! Há um obstáculo na outra dimensão.")
		# Se deu ruim, força todo mundo a voltar para o mundo atual
		get_tree().call_group("world_elements", "on_world_switched", current_world)
		piscar_tela_bloqueio()
		return # Cancela a troca e NÃO consome o item!
		
	# 6. SE CHEGOU AQUI, O CAMINHO ESTÁ LIVRE E VOCÊ TEM O ITEM! Confirma a troca definitiva
	current_world = next_world
	if current_world == 1:
		animated_sprite.sprite_frames = frames_mundo_1
	else:
		animated_sprite.sprite_frames = frames_mundo_2
		
	# [NOVO] 7. Consome o item do inventário apenas agora que a troca deu 100% certo!
	Inventario.remover_item("Troca")
	atualizar_ui_inventario() # Atualiza o texto da tela para sumir com o item gasto
	
	# 8. Força o mapa a se atualizar definitivamente para o novo mundo
	get_tree().call_group("world_elements", "on_world_switched", current_world)
	
	# 9. Atualiza o visual do cowboy
	change_world_visuals(Color(1.0, 1.0, 1.0))

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
	if Inventario.itens.size() == 0:
		texto_inventario.text = "Inventario: Vazio"
	else:
		var lista_formatada = ", ".join(Inventario.itens)
		texto_inventario.text = "Inventario: " + lista_formatada

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
