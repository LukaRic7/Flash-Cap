import loggerric as lr
import os, json
from pathlib import Path

class Settings:
    """
    Handles reading and writing to the settings file.

    ### Methods:
    - `get(*keys)`: Get the value of the key nest.
    - `set(value, *keys)`: Set the value of the key nest.
    """

    # Full path to the settings file
    _settings_path = os.path.join(
        os.getenv('APPDATA'),
        'LukaRicApps',
        'FlashCap',
        'settings.json'
    )

    # Make sure the apps data folder exists
    os.makedirs(os.path.dirname(_settings_path), exist_ok=True)

    # Keep track of the latest data as to not make too many open() calls
    _latest_data = None

    # Default settings
    _defaults = {
        'hotkeys': {
            'screenshot': 'ctrl+shift+s',
            'windowed_screenshot': 'ctrl+shift+w',
            'start_recording': 'ctrl+shift+r',
            'stop_recording': 'ctrl+shift+t'
        },
        'recording': {
            'fps': 30
        },
        'output': {
            'directory': str(Path.home() / 'Videos' / 'FlashCap')
        }
    }

    @staticmethod
    def _load_data():
        try:
            with open(Settings._settings_path, 'r') as file:
                data = json.load(file)
        except FileNotFoundError:
            data = Settings._defaults.copy()
            with open(Settings._settings_path, 'w') as file:
                json.dump(data, file, indent=4)
        # Merge with defaults for missing keys
        def merge_defaults(target, source):
            for key, value in source.items():
                if key not in target:
                    target[key] = value
                elif isinstance(value, dict) and isinstance(target[key], dict):
                    merge_defaults(target[key], value)
        merge_defaults(data, Settings._defaults)
        Settings._latest_data = data
        return data

    @staticmethod
    def get(*keys):
        """
        Get the value of the key nest.

        ### Parameters:
        - `*keys`: Key nest.

        ### Returns:
        Value stored at the end of the key nest.
        """

        lr.Log.debug('<Settings> Reading:', '.'.join(keys))

        data = Settings._load_data()

        for key in keys:
            # If the key points to nothing, return empty
            if data == None:
                return

            data = data.get(key)

        return data
    
    def set(value, *keys) -> None:
        """
        Set the value of the key nest.

        ### Parameters:
        - `value`: Value to write.
        - `*keys`: Key nest.
        """

        lr.Log.debug('<Settings> Writing:', '.'.join(keys), f'= {value}')

        data = Settings._load_data()

        # Create a pointer, as to not lose root reference (data)
        section = data

        # Iterate all but the last key
        for key in keys[:-1]:
            section = section.setdefault(key, {})
        
        # Assign new value to the final key in the nest
        section[keys[-1]] = value

        with open(Settings._settings_path, 'w') as file:
            json.dump(data, file, indent=4)
        
        # Update cache
        Settings._latest_data = data