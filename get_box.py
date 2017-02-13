import os
from platform import system


def box_home():
    _system = system()

    if _system in ('Windows', 'cli'):
        info_path = os.path.join(os.getenv('APPDATA'), 'Box Sync', 'info.json')
        if not os.path.isfile(info_path):
            info_path = os.path.join(os.getenv('LOCALAPPDATA'), 'Box Sync', 'info.json')

    elif _system in ('Darwin'):
        user_home = os.path.expanduser('~')
        info_path = os.path.join(user_home, 'Library', 'Application Support',
                                 'Box', 'Box Sync', 'sync_root_folder.txt')
    elif _system in ('Linux'):
       raise RuntimeError("Box doesn't run on Linux.")
    else:
        raise RuntimeError('Unknown system: {}'.format(_system))
    if not os.path.isfile(info_path):
        err_msg = ("Could not find the Box sync_root_folder.txt file! (Should be here:" +
                   " '" + info_path + "')")
        raise FileNotFoundError(err_msg)

    with open(info_path, 'r') as f:
        box_dir = f.readline().rstrip('\n\r')

    if not os.path.isdir(box_dir):
        err_msg = ("Box configuration indicated the Box directory was '" + box_dir +
                   "', but that doesn't exist.")
        raise FileNotFoundError(err_msg)
    return box_dir

print(box_home())
