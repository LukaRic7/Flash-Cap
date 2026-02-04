import subprocess
import numpy as np
import cv2
from pathlib import Path
from utils.settings import Settings

class Encoder:
    def __init__(self, output_path: str, fps: int = 30, format: str = 'mp4'):
        self.output_path = Path(output_path)
        self.fps = fps
        self.format = format.lower()
        self.process = None
        self.width = None
        self.height = None

    def start_encoding(self, first_frame: np.ndarray):
        self.height, self.width = first_frame.shape[:2]
        if self.format == 'mp4':
            self._start_mp4_encoding()
        elif self.format == 'gif':
            self._start_gif_encoding()
        else:
            raise ValueError(f"Unsupported format: {self.format}")

    def _start_mp4_encoding(self):
        cmd = [
            'ffmpeg',
            '-y',  # Overwrite output
            '-f', 'rawvideo',
            '-pix_fmt', 'rgb24',
            '-s', f'{self.width}x{self.height}',
            '-r', str(self.fps),
            '-i', '-',  # Input from stdin
            '-c:v', 'libx264',
            '-preset', 'fast',
            '-crf', '23',
            str(self.output_path)
        ]
        self.process = subprocess.Popen(cmd, stdin=subprocess.PIPE)

    def _start_gif_encoding(self):
        # For GIF, use ffmpeg with palette
        cmd = [
            'ffmpeg',
            '-y',
            '-f', 'rawvideo',
            '-pix_fmt', 'rgb24',
            '-s', f'{self.width}x{self.height}',
            '-r', str(self.fps),
            '-i', '-',
            '-vf', 'palettegen=stats_mode=diff[pal],[0:v][pal]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle',
            str(self.output_path)
        ]
        self.process = subprocess.Popen(cmd, stdin=subprocess.PIPE)

    def encode_frame(self, frame: np.ndarray):
        if self.process and self.process.stdin:
            # Ensure frame is RGB and correct size
            if frame.shape[:2] != (self.height, self.width):
                frame = cv2.resize(frame, (self.width, self.height))
            self.process.stdin.write(frame.tobytes())

    def finish_encoding(self):
        if self.process and self.process.stdin:
            self.process.stdin.close()
        if self.process:
            self.process.wait()