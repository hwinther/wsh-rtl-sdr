"""Start dump1090exporter (https://github.com/claws/dump1090-exporter) from the environment.

Replaces the old bash start script: the image has no shell. RESOURCE_PATH is readsb's JSON
directory or an http(s) URL to a /data endpoint; LAT/LON (optional) set the receiver position for
the max-range calculation, otherwise the exporter falls back to receiver.json. The command line is
not printed, so the position stays out of the logs.
"""

import os
import sys

from dump1090exporter.__main__ import main

args = [
    "dump1090exporter",
    f"--resource-path={os.environ.get('RESOURCE_PATH', '/run/readsb')}",
    f"--port={os.environ.get('EXPORTER_PORT', '9105')}",
]
for env, flag in (("LAT", "--latitude"), ("LON", "--longitude")):
    if os.environ.get(env):
        args.append(f"{flag}={os.environ[env]}")

sys.argv = args
sys.exit(main())
