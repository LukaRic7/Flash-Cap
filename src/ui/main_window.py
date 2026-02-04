from PySide6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit, QPushButton, QSpinBox, QGroupBox, QFileDialog
from PySide6.QtCore import Qt
from pathlib import Path
from utils.settings import Settings

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FlashCap Settings")
        self.setGeometry(300, 300, 400, 300)

        layout = QVBoxLayout()

        # Hotkeys group
        hotkeys_group = QGroupBox("Hotkeys")
        hotkeys_layout = QVBoxLayout()

        self.screenshot_edit = self.create_hotkey_edit("Screenshot", 'hotkeys', 'screenshot')
        self.start_rec_edit = self.create_hotkey_edit("Start Recording", 'hotkeys', 'start_recording')
        self.stop_rec_edit = self.create_hotkey_edit("Stop Recording", 'hotkeys', 'stop_recording')

        hotkeys_layout.addWidget(self.screenshot_edit)
        hotkeys_layout.addWidget(self.start_rec_edit)
        hotkeys_layout.addWidget(self.stop_rec_edit)
        hotkeys_group.setLayout(hotkeys_layout)
        layout.addWidget(hotkeys_group)

        # Recording group
        rec_group = QGroupBox("Recording")
        rec_layout = QVBoxLayout()
        self.fps_spin = QSpinBox()
        self.fps_spin.setRange(1, 60)
        self.fps_spin.setValue(Settings.get('recording', 'fps') or 30)
        rec_layout.addWidget(QLabel("FPS:"))
        rec_layout.addWidget(self.fps_spin)
        rec_group.setLayout(rec_layout)
        layout.addWidget(rec_group)

        # Output group
        output_group = QGroupBox("Output Directory")
        output_layout = QHBoxLayout()
        self.output_edit = QLineEdit(Settings.get('output', 'directory') or str(Path.home() / 'Videos' / 'FlashCap'))
        self.output_edit.setReadOnly(True)
        browse_btn = QPushButton("Browse")
        browse_btn.clicked.connect(self.browse_output)
        output_layout.addWidget(self.output_edit)
        output_layout.addWidget(browse_btn)
        output_group.setLayout(output_layout)
        layout.addWidget(output_group)

        # Save button
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_settings)
        layout.addWidget(save_btn)

        self.setLayout(layout)

    def create_hotkey_edit(self, label, *keys):
        layout = QHBoxLayout()
        layout.addWidget(QLabel(f"{label}:"))
        edit = QLineEdit(Settings.get(*keys) or "")
        layout.addWidget(edit)
        widget = QWidget()
        widget.setLayout(layout)
        return widget

    def browse_output(self):
        dir_path = QFileDialog.getExistingDirectory(self, "Select Output Directory")
        if dir_path:
            self.output_edit.setText(dir_path)

    def save_settings(self):
        # Save hotkeys
        screenshot_text = self.screenshot_edit.layout().itemAt(1).widget().text()
        start_text = self.start_rec_edit.layout().itemAt(1).widget().text()
        stop_text = self.stop_rec_edit.layout().itemAt(1).widget().text()
        Settings.set(screenshot_text, 'hotkeys', 'screenshot')
        Settings.set(start_text, 'hotkeys', 'start_recording')
        Settings.set(stop_text, 'hotkeys', 'stop_recording')

        # Save fps
        Settings.set(self.fps_spin.value(), 'recording', 'fps')

        # Save output
        Settings.set(self.output_edit.text(), 'output', 'directory')

        self.close()
