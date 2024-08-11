#!/usr/bin/python
import os
import sys
import signal
import subprocess
import codecs
import json
import time


report = {}
freqs = open('scan.out', 'r').read().split('\n')
if '' in freqs: freqs.remove('')

i = 1
for freq in freqs:
    print('scanning %s (%d/%d)' % (freq, i, len(freqs)))
    i += 1
    cmd = 'grgsm_livemon -f %s -g 49.6 -s 3.2M' % freq
    cmd2 = 'python imsi.py'
    # print(cmd)
    # print(cmd2)
    timeout_s = 2
    timeout_s2 = 60
    grace_period_s = 2
    imsi_json_path = 'imsi.json'

    p = subprocess.Popen(cmd.split(' '), start_new_session=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if os.path.exists(imsi_json_path):
        os.unlink(imsi_json_path)
    p2 = subprocess.Popen(cmd2.split(' '), start_new_session=True, stderr=subprocess.PIPE)

    try:
        p2.wait(timeout=timeout_s2)
    except subprocess.TimeoutExpired:
        # print(f'Timeout for {cmd} ({timeout_s}s) expired', file=sys.stderr)
        print('Terminating imsi.py', file=sys.stderr)
        os.killpg(os.getpgid(p2.pid), signal.SIGTERM)

    try:
        p.wait(timeout=timeout_s)
    except subprocess.TimeoutExpired:
        print('Terminating grgsm', file=sys.stderr)
        os.killpg(os.getpgid(p.pid), signal.SIGTERM)

    if not os.path.exists(imsi_json_path):
        report[freq] = None
        print('No data')
        time.sleep(grace_period_s)
        continue

    with open(imsi_json_path, 'r') as f:
        data = json.load(f)
    print('dBm: %s ci: %s operator: %s' % (data['signal_dbm'], data['ci'], data['lookup']['operator']))
    report[freq] = data

    # result = subprocess.call([cmd], shell=True, capture_output=True, text=True, timeout=30)
    # print(result)

    # break
    time.sleep(grace_period_s)

print('\n\nFinal report:\n\n')
for freq, data in report.items():
    if data is None:
        print('Freq: %s - No data' % freq)
    else:
        print('Freq: %s dBm: %s ci: %s operator: %s' % (freq, data['signal_dbm'], data['ci'], data['lookup']['operator']))

with open('auto.json', 'w') as f:
    json.dump(report, f)
print('\nWrote data to auto.json')
