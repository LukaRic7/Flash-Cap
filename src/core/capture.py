import numpy as np
import mss

class ScreenCapture:
    def __init__(self):
        self.sct = mss.mss()
        self.monitor = self.sct.monitors[1]
    
    def frame(self):
        shot = self.sct.grab(self.monitor)
        return np.array(shot)