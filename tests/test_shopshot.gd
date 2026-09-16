extends SceneTree
## Screenshot shop: ShopUI standalone + manajer, buka, simpan PNG, quit.

const RunS = preload("res://scripts/run_manager.gd")
const JokerS = preload("res://scripts/joker_manager.gd")
const Hands = preload("res://scripts/hand_manager.gd")
const ShopS = preload("res://scripts/shop_ui.gd")

func _init() -> void:
	var run = RunS.new()
	root.add_child(run)
	var jok = JokerS.new()
	root.add_child(jok)
	var hm = Hands.new()
	root.add_child(hm)
	var shop = ShopS.new()
	root.add_child(shop)
	await process_frame
	await process_frame
	run.add_money(12)
	hm.deal(1) # pastikan deck kebentuk
	shop.setup(run, jok, hm.deck, hm)
	shop.open_shop(1)
	for i in range(30):
		await process_frame
	var img := root.get_texture().get_image()
	var path := "C:/Users/Nessa/AppData/Local/Temp/opencode/beatemfold_shop.png"
	var err := img.save_png(path)
	print("SHOPSHOT saved err=%d" % err)
	quit(0)
