from datetime import datetime
from pathlib import Path
import sys, threading
import loggerric as lr

from PySide6.QtWidgets import QApplication
from PIL import Image

from utils.settings import Settings
from core.capture import ScreenCapture
from ui.selection import RectSelector
from core.recorder import Recorder
from ui.main_window import MainWindow
from ui.tray import create_tray
from core.hotkeys import *

class FlashCapApp:
    def __init__(self):
        self.capture = ScreenCapture()
        self.recorder = Recorder()
        self.settings_window = None

    def take_screenshot(self):
        lr.Log.debug('Take SS')
        RectSelector(self._on_region_selected)

    def _on_region_selected(self, rect):
        x, y, w, h = rect.x(), rect.y(), rect.width(), rect.height()
        img = self.capture.capture_region(x, y, w, h)
        output_dir = Path(Settings.get('output', 'directory') or Path.home() / 'Pictures' / 'FlashCap')
        output_dir.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_path = output_dir / f'screenshot_{timestamp}.png'
        Image.fromarray(img).save(str(output_path))

    def start_recording(self):
        self.recorder.start_recording('mp4')

    def stop_recording(self):
        self.recorder.stop_recording()

    def open_settings(self):
        if self.settings_window is None:
            self.settings_window = MainWindow()
        self.settings_window.show()
        self.settings_window.raise_()
        self.settings_window.activateWindow()

    def exitapp(self):
        self.recorder.stop_recording()
        QApplication.quit()
    
def main():
    qt = QApplication(sys.argv)

    app = FlashCapApp()

    tray = create_tray(app.open_settings, app.start_recording, app.stop_recording, app.take_screenshot, app.exitapp)

    register_screenshot(app.take_screenshot)
    #register_start_recording(app.start_recording)
    #register_stop_recording(app.stop_recording)
    #register_windowed_screenshot(lambda: print('ger'))

    sys.exit(qt.exec())

if __name__ == '__main__':
    main()