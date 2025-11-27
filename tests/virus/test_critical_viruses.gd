extends GutTest

const GLITCH_SCENE := preload("res://src/virus/types/GlitchVirus.tscn")
const ADWARE_SCENE := preload("res://src/virus/types/AdwareVirus.tscn")
const POPUP_SCENE := preload("res://src/virus/types/PopupVirus.tscn")
const PHISHING_SCENE := preload("res://src/virus/types/PhishingVirus.tscn")
const FAKE_UPDATE_SCENE := preload("res://src/virus/types/app_viruses/FakeUpdateVirus.tscn")
const CAPTCHA_SCENE := preload("res://src/virus/types/app_viruses/CaptchaVirus.tscn")
const SURVEY_SCENE := preload("res://src/virus/types/app_viruses/SurveyVirus.tscn")

func test_glitch_signals() -> void:
	await _assert_signal_flow(GLITCH_SCENE, Callable(self, "_glitch_success"), Callable(self, "_glitch_failure"), "GlitchVirus")

func test_adware_signals() -> void:
	await _assert_signal_flow(ADWARE_SCENE, Callable(self, "_adware_success"), Callable(self, "_adware_failure"), "AdwareVirus")

func test_popup_signals() -> void:
	await _assert_signal_flow(POPUP_SCENE, Callable(self, "_popup_success"), Callable(self, "_popup_failure"), "PopupVirus")

func test_phishing_signals() -> void:
	await _assert_signal_flow(PHISHING_SCENE, Callable(self, "_phishing_success"), Callable(self, "_phishing_failure"), "PhishingVirus")

func test_fake_update_signals() -> void:
	await _assert_signal_flow(FAKE_UPDATE_SCENE, Callable(self, "_fake_update_success"), Callable(self, "_fake_update_failure"), "FakeUpdateVirus")

func test_captcha_signals() -> void:
	await _assert_signal_flow(CAPTCHA_SCENE, Callable(self, "_captcha_success"), Callable(self, "_captcha_failure"), "CaptchaVirus")

func test_survey_signals() -> void:
	await _assert_signal_flow(SURVEY_SCENE, Callable(self, "_survey_success"), Callable(self, "_survey_failure"), "SurveyVirus")

func _assert_signal_flow(scene: PackedScene, success_callable: Callable, failure_callable: Callable, label: String) -> void:
	await _assert_single_signal(scene, success_callable, label + " success", true)
	await _assert_single_signal(scene, failure_callable, label + " failure", false)

func _assert_single_signal(scene: PackedScene, action: Callable, description: String, expect_success: bool) -> void:
	var virus: BaseVirus = scene.instantiate()
	add_child_autofree(virus)
	await get_tree().process_frame
	var signal_flag := [false]
	var target_signal: Signal = virus.virus_cleared if expect_success else virus.virus_failed
	target_signal.connect(func(): signal_flag[0] = true)
	var result = action.call(virus)
	await _await_possible_state(result)
	var completed := await _wait_until(func(): return signal_flag[0], 4.0)
	if expect_success:
		assert_true(completed, description + " should emit virus_cleared")
	else:
		assert_true(completed, description + " should emit virus_failed")
	virus.queue_free()

func _glitch_success(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._complete_virus()

func _glitch_failure(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._fail_virus()

func _adware_success(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._complete_virus()

func _adware_failure(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._fail_virus()

func _popup_success(virus: BaseVirus):
	await _ensure_started(virus)
	virus._complete_infection()

func _popup_failure(virus: BaseVirus):
	await _ensure_started(virus)
	virus._on_timer_timeout()

func _phishing_success(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._complete_virus()

func _phishing_failure(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._fail_virus()

func _fake_update_success(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._on_cancel_pressed()

func _fake_update_failure(virus: BaseVirus):
	await _ensure_started(virus)
	return virus._on_install_complete()

func _captcha_success(virus: BaseVirus):
	await _ensure_started(virus)
	await get_tree().process_frame
	virus.selected_indices = virus.correct_indices.duplicate()
	virus.verify_button.disabled = false
	return virus._on_verify_pressed()

func _captcha_failure(virus: BaseVirus):
	await _ensure_started(virus)
	await get_tree().process_frame
	virus.current_attempts = virus.max_attempts - 1
	virus.selected_indices = []
	virus.verify_button.disabled = false
	return virus._on_verify_pressed()

func _survey_success(virus: BaseVirus):
	await _ensure_started(virus)
	await get_tree().process_frame
	for question_data in virus.SURVEY_QUESTIONS:
		virus.selected_answer = question_data.safe_answer
		virus.submit_button.disabled = false
		var state = virus._on_submit_pressed()
		await _await_possible_state(state)
		await get_tree().process_frame
	await get_tree().process_frame

func _survey_failure(virus: BaseVirus):
	await _ensure_started(virus)
	await get_tree().process_frame
	virus.selected_answer = 0
	virus.submit_button.disabled = false
	return virus._on_submit_pressed()

func _ensure_started(virus: BaseVirus) -> void:
	var start_state = virus.call("start_infection")
	await _await_possible_state(start_state)
	await get_tree().process_frame

func _await_possible_state(value) -> void:
	if value == null:
		return
	if typeof(value) != TYPE_OBJECT:
		return
	if not value.has_method("is_completed"):
		return
	if value.is_completed():
		return
	await value

func _wait_until(predicate: Callable, timeout: float = 3.0) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if predicate.call():
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return false
