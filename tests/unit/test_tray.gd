extends TestCase


func test_groups_by_type() -> void:
	var t := Tray.new()
	t.insert(0, 1)
	t.insert(1, 2)
	t.insert(0, 3)
	eq(t.types, [0, 0, 1] as Array[int])
	eq(t.uids, [1, 3, 2] as Array[int])


func test_three_alike_clear() -> void:
	var t := Tray.new()
	for i in 3:
		t.insert(4, i)
	var r := t.resolve()
	eq(r.type, 4)
	eq(r.uids.size(), 3)
	eq(t.size(), 0)


func test_no_clear_for_two() -> void:
	var t := Tray.new()
	t.insert(1, 1)
	t.insert(1, 2)
	check(t.resolve().is_empty())


func test_rainbow_completes_pair() -> void:
	var t := Tray.new()
	t.insert(2, 1)
	t.insert(3, 2)
	t.insert(2, 3)
	t.insert(Sticker.RAINBOW, 4)
	var r := t.resolve()
	eq(r.type, 2)
	eq(t.types, [3] as Array[int])


func test_rainbow_waits_without_pair() -> void:
	var t := Tray.new()
	t.insert(Sticker.RAINBOW, 1)
	t.insert(5, 2)
	check(t.resolve().is_empty(), "a rainbow does not clear a single")
	t.insert(5, 3)
	eq(t.resolve().type, 5, "then completes the pair")


func test_full() -> void:
	var t := Tray.new()
	for i in 7:
		t.insert(i, i)
	check(t.is_full())
