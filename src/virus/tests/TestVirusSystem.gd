extends Node

## Test script for Virus System
## Run this scene to verify virus spawning and logic

func _ready():
	print("🧪 Starting Virus System Test...")
	
	# Wait for systems to initialize
	await get_tree().create_timer(1.0).timeout
	
	if not VirusController:
		push_error("❌ VirusController not found! Is it registered as Autoload?")
		return
		
	print("✅ VirusController found.")
	
	# Test 1: Trigger Glitch Virus
	print("\n🧪 Testing Glitch Virus...")
	VirusController.trigger_infection("glitch")
	await get_tree().create_timer(2.0).timeout
	
	if VirusController.is_infected:
		print("✅ Glitch Virus spawned successfully.")
	else:
		push_error("❌ Glitch Virus failed to spawn.")
		
	# Simulate clearing (hacky, just for test)
	if VirusController.overlay_instance:
		var virus = VirusController.overlay_instance.container.get_child(0)
		if virus:
			print("   Simulating clear...")
			virus._complete_virus()
			await get_tree().create_timer(2.0).timeout
	
	# Test 2: Trigger Adware Virus
	print("\n🧪 Testing Adware Virus...")
	VirusController.trigger_infection("adware")
	await get_tree().create_timer(2.0).timeout
	
	if VirusController.is_infected:
		print("✅ Adware Virus spawned successfully.")
		# Simulate clear
		if VirusController.overlay_instance:
			var virus = VirusController.overlay_instance.container.get_child(0)
			if virus:
				virus._complete_virus()
				await get_tree().create_timer(2.0).timeout
	
	# Test 3: Trigger Phishing Virus
	print("\n🧪 Testing Phishing Virus...")
	VirusController.trigger_infection("phishing")
	await get_tree().create_timer(2.0).timeout
	
	if VirusController.is_infected:
		print("✅ Phishing Virus spawned successfully.")
		# Simulate clear
		if VirusController.overlay_instance:
			var virus = VirusController.overlay_instance.container.get_child(0)
			if virus:
				virus._complete_virus()
				await get_tree().create_timer(2.0).timeout
				
	print("\n🎉 All tests completed!")
