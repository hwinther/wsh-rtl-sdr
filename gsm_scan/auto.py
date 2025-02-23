#!/usr/bin/python3
import os
import sys
import signal
import subprocess
import codecs
import json
import time
import argparse


def main(filename=None, headless=None, wait_time=None, verbose=None):
    filename = 'scan.out' if filename is None else filename
    grgsm_cmd = 'grgsm_livemon_headless' if headless else 'grgsm_livemon'
    wait_time = wait_time if type(wait_time) == type(int) else 60
    verbose = True if verbose else False

    report = {}
    freqs = open('scan.out', 'r').read().split('\n')
    if '' in freqs: freqs.remove('')

    i = 1
    for freq in freqs:
        print('scanning %s (%d/%d)' % (freq, i, len(freqs)))
        i += 1
        cmd = f'{grgsm_cmd} -f {freq} -g 49.6 -s 3.2M'
        cmd2 = 'python3 imsi.py'
        if verbose: print(cmd)
        # print(cmd2)
        timeout_s = 2
        timeout_s2 = wait_time  # 60
        grace_period_s = 2
        imsi_json_path = 'imsi.json'

        p = subprocess.Popen(cmd.split(' '), start_new_session=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if os.path.exists(imsi_json_path):
            os.unlink(imsi_json_path)
        p2 = subprocess.Popen(cmd2.split(' '), start_new_session=True, stderr=subprocess.PIPE)

        try:
            p2.wait(timeout=timeout_s2)
        except subprocess.TimeoutExpired:
            if verbose: print(f'Timeout for {cmd} ({timeout_s}s) expired', file=sys.stderr)
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

        try:
            print('dBm: %s ci: %s operator: %s' % (data['signal_dbm'], data['ci'], data['lookup']['operator']))
            report[freq] = data
        except:
            print('failed to parse data:\n%s' % repr(data))

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

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='auto.py', description='Scans each frequency in the scan.out file for MCC/telco id', epilog='author: dgram')
    parser.add_argument('-f', '--filename')
    parser.add_argument('-hl', '--headless', action='store_true')
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('-wt', '--wait_time', type=int)
    args = parser.parse_args()
    main(filename=args.filename, headless=args.headless, wait_time=args.wait_time, verbose=args.verbose)
