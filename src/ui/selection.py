from PySide6.QtWidgets import QWidget, QApplication
from PySide6.QtCore import Qt, QRect, QPoint, QTimer
from PySide6.QtGui import QPainter, QColor, QPen
from typing import Callable
import loggerric as lr

class RectSelector(QWidget):
    def __init__(self, callback: Callable[[QRect], None]):
        super().__init__()
        self.callback = callback
        self.start = QPoint()
        self.pressed = False

        # Topmost, frameless, tool window, transparent for input
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool | Qt.WindowTransparentForInput)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setStyleSheet("background-color: rgba(0, 180, 255, 50);")  # Semi-transparent blue
        self.setWindowOpacity(0.5)

        # Start with zero size
        self.setGeometry(0, 0, 0, 0)
        self.show()
        self.raise_()

        # Timer to poll mouse position
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_selection)
        self.timer.start(10)  # ~100 FPS

    def update_selection(self):
        # Poll mouse state
        mouse_pos = QApplication.instance().cursor().pos()
        lbutton_pressed = QApplication.mouseButtons() & Qt.LeftButton

        if not self.pressed:
            if lbutton_pressed:
                self.start = mouse_pos
                self.pressed = True
                self.setGeometry(self.start.x(), self.start.y(), 0, 0)
        else:
            if lbutton_pressed:
                x = min(self.start.x(), mouse_pos.x())
                y = min(self.start.y(), mouse_pos.y())
                w = abs(mouse_pos.x() - self.start.x())
                h = abs(mouse_pos.y() - self.start.y())
                self.setGeometry(x, y, w, h)
            else:
                # Released
                x = min(self.start.x(), mouse_pos.x())
                y = min(self.start.y(), mouse_pos.y())
                w = abs(mouse_pos.x() - self.start.x())
                h = abs(mouse_pos.y() - self.start.y())
                rect = QRect(x, y, w, h)
                self.callback(rect)
                self.timer.stop()
                self.close()

    def paintEvent(self, event):
        # Not needed
        pass