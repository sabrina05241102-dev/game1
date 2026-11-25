extends Control

const SAVE_PATH := "user://little_money_save.json"
const GREEN := Color("28634e")
const PALE := Color("eaf0df")
const PAPER := Color("fbf9f4")
const LINE := Color("e9e5db")
const PRODUCTS := [
	{"id":"pencil", "icon":"✏️", "name":"彩虹鉛筆", "price":8, "need":true},
	{"id":"notebook", "icon":"📓", "name":"星星筆記本", "price":15, "need":true},
	{"id":"snack", "icon":"🍎", "name":"水果點心", "price":12, "need":true},
	{"id":"toy", "icon":"🪀", "name":"跳跳球", "price":15, "need":false}
]
var cash := 120
var savings := 0
var investment := 0
var day := 1
var stock := 0
var stock_cost := 0
var shop_price := 12
var budget := 50
var cart := {"pencil":0, "notebook":0, "snack":0, "toy":0}
var flows: Array[Dictionary] = []
var lesson := "先想想需要什麼，再決定想要什麼。預算有限時，做好選擇很重要！"
var feedback := ""
var current_tab := "shop"
var root_box: VBoxContainer
var content_box: VBoxContainer
var status_label: Label
var feedback_label: Label

func _ready() -> void:
	_load_game()
	var game_theme := Theme.new()
	game_theme.default_font = load("res://fonts/NotoSansTC.ttf") as Font
	game_theme.default_font_size = 14
	theme = game_theme
	_build_shell()
	_render()

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 28
	scroll.offset_right = -28
	scroll.offset_top = 16
	scroll.offset_bottom = -18
	add_child(scroll)
	root_box = VBoxContainer.new()
	root_box.custom_minimum_size.x = 800
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 18)
	scroll.add_child(root_box)

func _render() -> void:
	for child in root_box.get_children():
		child.queue_free()
	var top := HBoxContainer.new()
	var brand := _label("🌿  小小理財家", 22, GREEN)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(brand)
	top.add_child(_label("📅 第 %d 天・校園市集" % day, 15))
	root_box.add_child(top)
	var hero := _panel(PALE)
	var hero_box := VBoxContainer.new()
	hero_box.add_child(_label("SCHOOL MARKET  ·  MONEY ADVENTURE", 12, GREEN))
	hero_box.add_child(_label("今天也來當理財小達人！", 32, Color("24352f")))
	hero_box.add_child(_label("經營文具店、聰明消費，讓每一塊錢都有好去處。", 15, Color("65776b")))
	var totals := HBoxContainer.new()
	totals.add_child(_label("💵 手邊現金  %s" % _money(cash), 19, GREEN))
	totals.add_child(_label("     🏺 儲蓄罐  %s" % _money(savings), 19, GREEN))
	hero_box.add_child(totals)
	hero.add_child(hero_box)
	root_box.add_child(hero)
	var tabs := HBoxContainer.new()
	for entry in [["shop","🏪 文具店"],["spend","🛍️ 消費區"],["save","🏺 儲蓄區"],["invest","📈 投資區"]]:
		var button := _button(entry[1], entry[0] == current_tab)
		button.pressed.connect(_select_tab.bind(entry[0]))
		tabs.add_child(button)
	root_box.add_child(tabs)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	content_box = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.custom_minimum_size.x = 520
	content_box.add_theme_constant_override("separation", 12)
	columns.add_child(content_box)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 230
	side.add_theme_constant_override("separation", 12)
	columns.add_child(side)
	root_box.add_child(columns)
	_build_section()
	var map := _panel(Color.WHITE)
	var map_box := VBoxContainer.new()
	map_box.add_child(_label("🧭 我的資金地圖", 17, GREEN))
	map_box.add_child(_label("💵 手邊現金　　 %s" % _money(cash), 14))
	map_box.add_child(_label("🏺 儲蓄罐　　　 %s" % _money(savings), 14))
	map_box.add_child(_label("📈 投資帳戶　　 %s" % _money(investment), 14))
	map_box.add_child(_label("✨ 總資產　　　 %s" % _money(cash+savings+investment), 15, GREEN))
	map.add_child(map_box)
	side.add_child(map)
	var flow_panel := _panel(Color.WHITE)
	var flow_box := VBoxContainer.new()
	flow_box.add_child(_label("🔄 今天的現金流", 16, GREEN))
	if flows.is_empty():
		flow_box.add_child(_label("完成活動後，資金流向會顯示在這裡。", 12, Color("738078")))
	else:
		for entry in flows.slice(0, 5):
			flow_box.add_child(_label("%s %s  %s" % [entry.icon, entry.label, _money(entry.amount)], 12))
	flow_panel.add_child(flow_box)
	side.add_child(flow_panel)
	var tip_panel := _panel(Color("f6efd9"))
	tip_panel.add_child(_label("💡 理財小知識\n" + lesson, 13, Color("6f6246")))
	side.add_child(tip_panel)
	feedback_label = _label(feedback, 14, GREEN)
	root_box.add_child(feedback_label)
	status_label = _label("進度會自動儲存在這台裝置的瀏覽器。", 12, Color("738078"))
	root_box.add_child(status_label)

func _build_section() -> void:
	var card := _panel(Color.WHITE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	content_box.add_child(card)
	match current_tab:
		"shop": _shop_view(box)
		"spend": _spend_view(box)
		"save": _save_view(box)
		"invest": _invest_view(box)

func _shop_view(box: VBoxContainer) -> void:
	box.add_child(_label("🏪 我的文具小舖", 21, GREEN))
	box.add_child(_label("進貨要花成本，設定售價後賣出商品，看看能不能賺錢！", 13))
	box.add_child(_label("收入 − 成本 = 利潤", 15, Color("8b7437")))
	for product in [{"icon":"✏️","name":"彩虹鉛筆","cost":4},{"icon":"📒","name":"星星筆記本","cost":7},{"icon":"🖍️","name":"蠟筆小盒","cost":9}]:
		var row := HBoxContainer.new()
		row.add_child(_label("%s %s  成本 %s" % [product.icon, product.name, _money(product.cost)], 13))
		var amount := SpinBox.new()
		amount.min_value = 1
		amount.max_value = 20
		amount.value = 1
		amount.custom_minimum_size.x = 72
		row.add_child(amount)
		var price := SpinBox.new()
		price.min_value = 1
		price.max_value = 99
		price.value = shop_price
		price.custom_minimum_size.x = 80
		row.add_child(price)
		var buy := _button("進貨")
		buy.pressed.connect(_buy.bind(product.cost, amount, price))
		row.add_child(buy)
		box.add_child(row)
	box.add_child(_label("目前庫存 %d 個　・　累計成本 %s" % [stock, _money(stock_cost)], 13))
	var sell := _button("🌟 今天收攤，賣出庫存")
	sell.pressed.connect(_sell)
	box.add_child(sell)

func _spend_view(box: VBoxContainer) -> void:
	box.add_child(_label("🛍️ 消費選擇題", 21, GREEN))
	box.add_child(_label("預算 %s：買齊三項必需品，再挑一件喜歡的物品。" % _money(budget), 13))
	for product in PRODUCTS:
		var row := HBoxContainer.new()
		row.add_child(_label("%s %s  %s  %s" % [product.icon, product.name, "需要" if product.need else "想要", _money(product.price)], 13))
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var less := _button("−")
		less.pressed.connect(_change_cart.bind(product.id, -1))
		row.add_child(less)
		row.add_child(_label(str(cart[product.id]), 13))
		var more := _button("+")
		more.pressed.connect(_change_cart.bind(product.id, 1))
		row.add_child(more)
		box.add_child(row)
	box.add_child(_label("選購總額：%s　／　預算 %s" % [_money(_cart_total()), _money(budget)], 15, GREEN))
	var checkout := _button("完成結帳")
	checkout.pressed.connect(_checkout)
	box.add_child(checkout)

func _save_view(box: VBoxContainer) -> void:
	box.add_child(_label("🏺 會長大的儲蓄罐", 21, GREEN))
	box.add_child(_label("目前存款：%s" % _money(savings), 25, GREEN))
	box.add_child(_label("存一小部分起來，為未來的自己做準備。需要時也能領出使用。", 13))
	var amount := SpinBox.new()
	amount.min_value = 1
	amount.max_value = 9999
	amount.value = 10
	box.add_child(amount)
	var deposit := _button("存入儲蓄罐")
	deposit.pressed.connect(_move_savings.bind(amount, true))
	box.add_child(deposit)
	var withdraw := _button("領出使用")
	withdraw.pressed.connect(_move_savings.bind(amount, false))
	box.add_child(withdraw)

func _invest_view(box: VBoxContainer) -> void:
	box.add_child(_label("📈 小小投資體驗", 21, GREEN))
	box.add_child(_label("投資帳戶價值：%s" % _money(investment), 25, GREEN))
	box.add_child(_label("市場每天隨機上漲或下跌，結果不一定如預期。", 13))
	var amount := SpinBox.new()
	amount.min_value = 1
	amount.max_value = 9999
	amount.value = 20
	box.add_child(amount)
	var invest := _button("投入資金")
	invest.pressed.connect(_invest.bind(amount))
	box.add_child(invest)
	var market := _button("🎲 模擬市場變化")
	market.pressed.connect(_market_change)
	box.add_child(market)
	var take := _button("取回投資")
	take.pressed.connect(_cash_out)
	box.add_child(take)
	box.add_child(_label("投資可能獲利，也可能虧損。不要投入全部的錢，記得保留儲蓄。", 13, Color("8b7437")))

func _buy(cost: int, amount: SpinBox, price: SpinBox) -> void:
	var count := int(amount.value)
	var total := cost * count
	if total > cash:
		_feedback("現金不夠，試試少進一點！")
		return
	cash -= total
	stock += count
	stock_cost += total
	shop_price = int(price.value)
	_add_flow("📦", "文具進貨", -total)
	_feedback("進貨 %d 個，花了 %s！" % [count, _money(total)])
	_refresh()

func _sell() -> void:
	if stock < 1:
		_feedback("還沒有庫存喔，先進貨再收攤！")
		return
	var income := stock * shop_price
	var cost := stock_cost
	var profit := income - cost
	cash += income
	stock = 0
	stock_cost = 0
	_add_flow("🛒", "文具銷售收入", income)
	lesson = "收入 %s − 成本 %s = 利潤 %s。%s" % [_money(income), _money(cost), _money(profit), "太棒了，這次賺錢！" if profit >= 0 else "下次可以調整售價或減少進貨！"]
	day += 1
	_feedback("收入 %s − 成本 %s = 利潤 %s" % [_money(income), _money(cost), _money(profit)])
	_refresh()

func _change_cart(id: String, delta: int) -> void:
	cart[id] = clampi(int(cart[id]) + delta, 0, 8)
	_refresh()

func _cart_total() -> int:
	var total := 0
	for product in PRODUCTS:
		total += product.price * int(cart[product.id])
	return total

func _checkout() -> void:
	for product in PRODUCTS:
		if product.need and int(cart[product.id]) < 1:
			_feedback("先把三項必需品各放進購物籃吧！")
			return
	if int(cart.toy) < 1:
		_feedback("還可以選一件想要的物品喔！")
		return
	var total := _cart_total()
	if total > budget:
		_feedback("超出預算了，調整一下購物籃吧！")
		return
	if total > cash:
		_feedback("手邊現金不足，先去經營文具店賺錢吧！")
		return
	cash -= total
	_add_flow("🛍️", "購買生活用品", -total)
	cart = {"pencil":0, "notebook":0, "snack":0, "toy":0}
	day += 1
	lesson = "先滿足生活需要，再用剩下的預算選擇想要的物品。花錢前看看預算，就不容易超支！"
	_feedback("成功結帳 %s，選擇得很棒！" % _money(total))
	current_tab = "save"
	_refresh()

func _move_savings(amount: SpinBox, deposit: bool) -> void:
	var n := int(amount.value)
	if deposit:
		if n > cash:
			_feedback("現金不足，量入為出喔！")
			return
		cash -= n
		savings += n
		_add_flow("🏺", "存入儲蓄罐", -n)
	else:
		if n > savings:
			_feedback("儲蓄罐裡沒有這麼多錢喔！")
			return
		savings -= n
		cash += n
		_add_flow("🏺", "從儲蓄罐領出", n)
	_feedback("已%s %s。" % ["存入" if deposit else "領出", _money(n)])
	_refresh()

func _invest(amount: SpinBox) -> void:
	var n := int(amount.value)
	if n > cash:
		_feedback("現金不足，留下生活需要的錢吧！")
		return
	cash -= n
	investment += n
	_add_flow("📈", "投入投資", -n)
	_feedback("投入 %s。記得投資有風險！" % _money(n))
	_refresh()

func _market_change() -> void:
	if investment <= 0:
		_feedback("先投入一些資金，才能體驗市場變化。")
		return
	var change := roundi(investment * randf_range(-0.2, 0.2))
	investment = maxi(0, investment + change)
	day += 1
	_add_flow("📈" if change >= 0 else "📉", "投資市場變化", change)
	lesson = "市場上漲，增加 %s。" % _money(change) if change >= 0 else "市場下跌，減少 %s。投資可能虧損，保留儲蓄很重要。" % _money(-change)
	_feedback("市場變化：%s%s" % ["+" if change >= 0 else "", _money(change)])
	_refresh()

func _cash_out() -> void:
	if investment <= 0:
		_feedback("投資帳戶目前沒有資金。")
		return
	var n := investment
	cash += n
	investment = 0
	_add_flow("💵", "取回投資", n)
	_feedback("已取回 %s，投資結果結算完成。" % _money(n))
	_refresh()

func _add_flow(icon: String, label: String, amount: int) -> void:
	flows.push_front({"icon":icon, "label":label, "amount":amount})
	if flows.size() > 10:
		flows.pop_back()

func _select_tab(tab: String) -> void:
	current_tab = tab
	_render()

func _refresh() -> void:
	_save_game()
	_render()

func _feedback(message: String) -> void:
	feedback = message
	feedback_label.text = message if is_instance_valid(feedback_label) else ""

func _money(amount: int) -> String:
	return "$%d" % amount

func _label(text: String, size: int = 14, color: Color = Color("24352f")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color, 18, Color("e9e5db")))
	return panel

func _button(text: String, selected: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color.WHITE if selected else GREEN)
	button.add_theme_stylebox_override("normal", _style(GREEN if selected else Color.WHITE, 12, GREEN if selected else LINE))
	button.add_theme_stylebox_override("hover", _style(Color("3a765d") if selected else Color("f0f4e5"), 12, GREEN))
	button.add_theme_stylebox_override("pressed", _style(Color("214e3e"), 12, GREEN))
	return button

func _style(fill: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = border
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _save_game() -> void:
	var data := {"cash":cash, "savings":savings, "investment":investment, "day":day, "stock":stock, "stock_cost":stock_cost, "shop_price":shop_price, "budget":budget, "cart":cart, "flows":flows, "lesson":lesson}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	cash = int(parsed.get("cash", cash))
	savings = int(parsed.get("savings", savings))
	investment = int(parsed.get("investment", investment))
	day = int(parsed.get("day", day))
	stock = int(parsed.get("stock", stock))
	stock_cost = int(parsed.get("stock_cost", stock_cost))
	shop_price = int(parsed.get("shop_price", shop_price))
	budget = int(parsed.get("budget", budget))
	cart = parsed.get("cart", cart)
	flows.clear()
	for entry in parsed.get("flows", []):
		if entry is Dictionary:
			flows.append(entry)
	lesson = str(parsed.get("lesson", lesson))
