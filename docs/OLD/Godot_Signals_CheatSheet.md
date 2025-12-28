# Understanding Godot Signals - CheatSheet

## Someone "emits" a signal (makes a phone call)

`emit_signal("customer_entered")`

## Someone else "connects" to listen (answers the phone)

`Events.customer_entered.connect(_on_customer_entered)`

## When the signal fires, this function runs

```
func _on_customer_entered():
    print("A customer just came in!")
```
