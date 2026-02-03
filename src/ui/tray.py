from PySide6.QtWidgets import QSystemTrayIcon, QMenu, QApplication
from PySide6.QtGui import QIcon
from typing import Callable

def create_tray(settings: Callable, suspend: Callable, exitapp: Callable) -> QSystemTrayIcon:
    tray = QSystemTrayIcon()
    tray.setIcon(QIcon("src/assets/trayicon.png"))

    menu = QMenu()
    menu.addAction("Open Settings", settings)
    menu.addAction("Suspend", suspend)
    menu.addAction("Quit", exitapp)

    tray.setContextMenu(menu)
    tray.show()

    return tray