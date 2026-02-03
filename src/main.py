from datetime import datetime
from pathlib import Path
import sys, threading

from PySide6.QtWidgets import QApplication

from core.capture import ScreenCapture
from ui.selection import RectSelector
from ui.tray import create_tray
from core.hotkeys import *

class FlashCapApp:
    def __init__(self):
        self.capture = ScreenCapture()

    def exitapp(self):
        QApplication.quit()
    
def main():
    qt = QApplication(sys.argv)

    app = FlashCapApp()

    tray = create_tray(lambda: 0, lambda: 0, app.exitapp)

    register_screenshot(lambda: RectSelector())
    #register_windowed_screenshot(lambda: print('ger'))

    sys.exit(qt.exec())

if __name__ == '__main__':
    main()