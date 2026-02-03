from PySide6.QtWidgets import QWidget, QApplication
from PySide6.QtCore import Qt, QRect, QPoint
from PySide6.QtGui import QPainter, QColor, QPen

class RectSelector(QWidget):
    def __init__(self):
        super().__init__()
        self.start = QPoint()
        self.end = QPoint()

        # Topmost, frameless
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool)
        self.setAttribute(Qt.WA_NoSystemBackground)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setMouseTracking(True)

        # Cover the full screen
        self.setGeometry(QApplication.primaryScreen().geometry())
        self.show()

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.start = event.globalPosition().toPoint()
            self.end = self.start
            self.update()

    def mouseMoveEvent(self, event):
        if event.buttons() & Qt.LeftButton:
            self.end = event.globalPosition().toPoint()
            self.update()

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.end = event.globalPosition().toPoint()
            self.update()
            self.close()  # Close overlay after release

    def paintEvent(self, event):
        # Clear background with fully transparent color
        painter = QPainter(self)
        painter.setCompositionMode(QPainter.CompositionMode_Source)
        painter.fillRect(self.rect(), QColor(0, 0, 0, 0))

        # Draw the selection rectangle
        if self.start != self.end:
            rect = QRect(self.start, self.end).normalized()
            pen = QPen(QColor(0, 180, 255), 2, Qt.SolidLine)
            brush = QColor(0, 180, 255, 50)
            painter.setPen(pen)
            painter.setBrush(brush)
            painter.drawRect(rect)