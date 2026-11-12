"""Start dump1090exporter (https://github.com/claws/dump1090-exporter) from the environment.

Replaces the old bash start script: the image has no shell. RESOURCE_PATH is readsb's JSON
directory or an http(s) URL to a /data endpoint; LAT/LON (optional) set the receiver position for
the max-range calculation, otherwise the exporter falls back to receiver.json. The command line is
not printed, so the position stays out of the logs.
"""

import asyncio
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
# dump1090exporter calls asyncio.get_event_loop() with no loop running, which raises RuntimeError
# since Python 3.14 (it used to create one). Set one first; get_event_loop() then returns it.
asyncio.set_event_loop(asyncio.new_event_loop())
sys.exit(main())
