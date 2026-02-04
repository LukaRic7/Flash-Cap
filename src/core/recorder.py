import threading
import time
from pathlib import Path
from datetime import datetime
from core.capture import ScreenCapture
from core.encoder import Encoder
from utils.settings import Settings

class Recorder:
    def __init__(self):
        self.capture = ScreenCapture()
        self.encoder = None
        self.recording = False
        self.thread = None
        self.fps = Settings.get('recording', 'fps') or 30

    def start_recording(self, format='mp4'):
        if self.recording:
            return
        self.recording = True
        output_dir = Path(Settings.get('output', 'directory') or Path.home() / 'Videos' / 'FlashCap')
        output_dir.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_path = output_dir / f'recording_{timestamp}.{format}'
        self.encoder = Encoder(str(output_path), self.fps, format)
        self.thread = threading.Thread(target=self._record_loop, daemon=True)
        self.thread.start()

    def _record_loop(self):
        first_frame = self.capture.frame()
        self.encoder.start_encoding(first_frame)
        while self.recording:
            frame = self.capture.frame()
            self.encoder.encode_frame(frame)
            time.sleep(1 / self.fps)

    def stop_recording(self):
        if not self.recording:
            return
        self.recording = False
        if self.thread:
            self.thread.join()
        if self.encoder:
            self.encoder.finish_encoding()
            self.encoder = None
