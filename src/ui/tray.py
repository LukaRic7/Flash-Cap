from PySide6.QtWidgets import QSystemTrayIcon, QMenu, QApplication
from PySide6.QtGui import QIcon
from typing import Callable

def create_tray(settings: Callable, start_rec: Callable, stop_rec: Callable, screenshot: Callable, exitapp: Callable) -> QSystemTrayIcon:
    tray = QSystemTrayIcon()
    tray.setIcon(QIcon("src/assets/trayicon.png"))

    menu = QMenu()
    menu.addAction("Start Recording", start_rec)
    menu.addAction("Stop Recording", stop_rec)
    menu.addAction("Take Screenshot", screenshot)
    menu.addSeparator()
    menu.addAction("Settings", settings)
    menu.addAction("Quit", exitapp)

    tray.setContextMenu(menu)
    tray.show()

    return tray