import numpy as np
import mss
import cv2

class ScreenCapture:
    def __init__(self):
        self.sct = mss.mss()
        self.monitor = self.sct.monitors[1]
    
    def frame(self):
        shot = self.sct.grab(self.monitor)
        img = np.array(shot)
        # Convert BGRA to RGB
        img = cv2.cvtColor(img, cv2.COLOR_BGRA2RGB)
        return img

    def capture_region(self, x, y, width, height):
        bbox = {'top': y, 'left': x, 'width': width, 'height': height}
        shot = self.sct.grab(bbox)
        img = np.array(shot)
        img = cv2.cvtColor(img, cv2.COLOR_BGRA2RGB)
        return img