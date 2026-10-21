cat << 'EOF' > README.md
# Plasma Notification App Icons

An Android-style notification app icon widget for **KDE Plasma 6**.

## Features

* **Android-Style Panel Row:** Displays deduplicated application icons for notifications directly on your panel.
* **Custom Idle Icon:** Choose the panel icon shown when there are no notifications.
* **Smart Growth:** Automatically grows left or right depending on which half of the screen the widget is placed on.
* **Interactive Popup:** Clicking the icon row opens a fully interactive popup matching native KDE notifications (complete with rich text, action buttons, quick reply, and Do Not Disturb controls).
* **Quick Dismissal:** Middle-click any panel icon to instantly clear that app's notifications, or click the individual close buttons in the popup.
* **Useful Tooltip:** Uses Plasma's widget tooltip to show the hovered app name and notification count, with no generic tooltip when no app icon is hovered.

---

## Installation

### Method 1: Build and Install from Source
1. Clone the repository:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/plasma-notification-icons.git](https://github.com/YOUR_USERNAME/plasma-notification-icons.git)
   cd plasma-notification-icons
   ```
2. Run `package.sh`
3. Install via `kpackagetool6 --type Plasma/Applet --install org.kde.notificationicons.plasmoid`
