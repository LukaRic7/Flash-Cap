from typing import Callable
import keyboard, threading
from pynput import mouse

from utils.settings import Settings

class HotkeyMouseListener:
    def __init__(self, hotkey: str, callback: Callable):
        self.hotkey = hotkey
        self.callback = callback
        self.lmb_pressed = False
        self.hotkey_active = False
        self.triggered = False  # <- Track if callback already ran for this press

        # Start mouse listener in background
        self.mouse_listener = mouse.Listener(on_click=self.on_click)
        self.mouse_listener.start()

        # Register hotkey
        keyboard.on_press_key(hotkey, self.on_hotkey_press)
        keyboard.on_release_key(hotkey, self.on_hotkey_release)

    def on_click(self, x, y, button, pressed):
        if button == mouse.Button.left:
            self.lmb_pressed = pressed
            if not pressed:
                # Reset trigger when button is released
                self.triggered = False
            else:
                self.try_callback()

    def on_hotkey_press(self, e):
        self.hotkey_active = True
        self.try_callback()

    def on_hotkey_release(self, e):
        self.hotkey_active = False
        # Optional: reset trigger when hotkey is released
        # self.triggered = False

    def try_callback(self):
        # Only call if both hotkey and LMB are active and not triggered yet
        if self.hotkey_active and self.lmb_pressed and not self.triggered:
            self.triggered = True  # Mark as triggered
            threading.Thread(target=self.callback, daemon=True).start()


# ----------------------
# Convenience functions
# ----------------------
def register_screenshot(callback: Callable) -> None:
    HotkeyMouseListener(Settings.get('hotkeys', 'screenshot'), callback)

def register_windowed_screenshot(callback: Callable) -> None:
    HotkeyMouseListener(Settings.get('hotkeys', 'windowed_screenshot'), callback)
