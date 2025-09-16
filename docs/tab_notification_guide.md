# Tab Notification System - Usage Guide

The tab notification system provides visual indicators for TabContainer tabs when new content is available.

## Setup

1. Import the system in your script:
```gdscript
const TabNotificationSystem = preload("res://scripts/ui/tab_notification_system.gd")
```

2. Create a variable to hold the system instance:
```gdscript
var tab_notification_system: TabNotificationSystem
```

3. Initialize it with your TabContainer:
```gdscript
var tab_container = $YourTabContainer
if tab_container:
    tab_notification_system = TabNotificationSystem.new(tab_container)
```

## Basic Usage

### Add a notification indicator
```gdscript
var target_tab = $YourTabContainer/YourTab
tab_notification_system.add_notification(target_tab)
# Tab title becomes "Original Title •"
```

### Remove a notification indicator
```gdscript
tab_notification_system.clear_notification(target_tab)
# Tab title returns to "Original Title"
```

### Switch to tab with notification
```gdscript
# Shows notification AND switches to that tab
tab_notification_system.switch_to_tab_with_notification(target_tab)
# User must navigate away and back to clear the indicator
```

## Common Use Cases

### Inventory Alerts
```gdscript
# When stock is low
var inventory_tab = $TabContainer/Inventory
if stock_level <= 5:
    tab_notification_system.add_notification(inventory_tab, "⚠")
```

### New Messages/Updates
```gdscript
# When new staff applications arrive
var staff_tab = $TabContainer/Staff
tab_notification_system.add_notification(staff_tab, "📩")
```

### Custom Indicators
```gdscript
# Different indicators for different types of alerts
tab_notification_system.add_notification(reports_tab, "•")  # Default
tab_notification_system.add_notification(alerts_tab, "!")   # Urgent
tab_notification_system.add_notification(mail_tab, "✉")     # Messages
```

## Auto-Clear Behavior

- Notifications automatically clear when users manually click the tab
- Programmatic tab switches (via `switch_to_tab_with_notification`) preserve the notification
- This ensures users see the indicator until they actively engage with the content

## Check Notification Status

```gdscript
if tab_notification_system.has_notification(target_tab):
    print("Tab has active notification")
```