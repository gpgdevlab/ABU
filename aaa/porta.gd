extends Area2D

# Permite que você escolha qual sala essa porta vai abrir direto pelo Inspetor
@export_file("*.tscn") var cena_destino: String

# Controla em qual mundo essa porta fica visível
@export var active_in_world: int = 1

func _ready() -> void:
	# Sistema de grupos idêntico ao do baú para sumir/aparecer nas dimensões
	add_to_group("world_elements")
	on_world_switched(1) # Começa checando o mundo inicial

func interact() -> void:
	if cena_destino == "":
		print("Erro: Nenhuma cena de destino foi configurada nesta porta!")
		return
		
	print("Entrando na sala...")
	# Muda o jogo para a nova cena da sala
	get_tree().change_scene_to_file(cena_destino)

# Controla a visibilidade nos mundos
func on_world_switched(target_world: int) -> void:
	if target_world == active_in_world:
		show()
		$CollisionShape2D.set_deferred("disabled", false)
	else:
		hide()
		$CollisionShape2D.set_deferred("disabled", true)
