import loggerric as lr
import os, json

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

        with open(Settings._settings_path, 'r') as file:
            data:dict = json.load(file)

            # Update cache
            Settings._latest_data = data

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

        # Grab the currently stored data from the cache, or read from the file
        if Settings._latest_data:
            data = Settings._latest_data
        else:
            try:
                with open(Settings._settings_path, 'r') as file:
                    data:dict = json.load(file)
            except FileNotFoundError:
                data = {}

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