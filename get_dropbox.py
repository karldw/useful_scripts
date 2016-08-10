import json
import os
from platform import system

def dropbox_home():
    _system = system()

    if _system in ('Windows', 'cli'):
        # https://www.dropbox.com/help/4584
        info_path = os.path.join(os.getenv('APPDATA'), 'Dropbox', 'info.json')
        if not os.path.isfile(info_path):
            info_path = os.path.join(os.getenv('LOCALAPPDATA'), 'Dropbox', 'info.json')


    elif _system in ('Linux', 'Darwin'):
        user_home = os.path.expanduser('~')
        info_path = os.path.join(user_home, '.dropbox', 'info.json')
    else:
        raise RuntimeError('Unknown system={}'
                           .format(_system))
    if not os.path.isfile(info_path):
        err_msg = "Could not find the Dropbox info.json file! (Should be here: '{}')".format(info_path)
        raise FileNotFoundError(err_msg)

    with open(info_path) as f:
        dropbox_settings = json.load(f)
    # if there are business and personal accounts, return both paths.
    paths = {k: v['path'] for k, v in dropbox_settings.items()}
    return paths
