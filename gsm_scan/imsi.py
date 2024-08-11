# coding: latin-1

"""
Large parts copied from dedsecimsi
"""

import pyshark
from optparse import OptionParser
import os, sys
import datetime
import json
import codecs

class ImsiEvil:

    sql_conn = None
    imsi = ""
    tmsi = ""
    mcc = ""
    mnc = ""
    lac = ""
    ci = ""
    signal_dbm = 0
    id_ = 0
    live_db = {}
    lookup_table = {}

    def load_lookup(self):
        self.lookup_table = {}
        data = json.loads(codecs.open('mcc-mnc-list.json', 'r', 'utf-8').read())
        for entry in data:
            self.lookup_table[(entry['mcc'], entry['mnc'])] = entry

    def get_imsi(self, capture):
        for packet in capture:
            # print('--------------------------------------')
            layer = packet.highest_layer
            if layer == "GSM_A.CCCH":
                print('layers 0=%s 1=%s 2=%s 3=%s 4=%s' % (packet[0].layer_name, packet[1].layer_name, packet[2].layer_name, packet[3].layer_name, packet[4].layer_name))
                if packet[4].layer_name == 'gsm_a.ccch':
                    gsmtap = packet[3]
                    gsm_a_ccch = packet[4]

                    if hasattr(gsmtap, "signal_dbm"):
                        # print('signal_dbm=%s' % (repr(gsmtap.signal_dbm)))
                        self.signal_dbm = int(gsmtap.signal_dbm)

                    if hasattr(gsm_a_ccch, "gsm_a_bssmap_cell_ci"):
                        self.ci = int(gsm_a_ccch.gsm_a_bssmap_cell_ci, 16)
                    if hasattr(gsm_a_ccch, "gsm_a_lac"):
                        # print('lac=%s' % (repr(gsm_a_ccch.gsm_a_lac)))
                        self.lac = int(gsm_a_ccch.gsm_a_lac, 16)

                    if hasattr(gsm_a_ccch, 'e212.imsi'):
                        self.imsi = gsm_a_ccch.e212_imsi #[-11:-1]
                        self.mcc = gsm_a_ccch.e212_mcc
                        self.mnc = gsm_a_ccch.e212_mnc
                        if hasattr(gsm_a_ccch,'gsm_a_rr_tmsi_ptmsi'):
                            self.tmsi = gsm_a_ccch.gsm_a_rr_tmsi_ptmsi
                        elif hasattr(gsm_a_ccch,'gsm_a_tmsi'):
                            self.tmsi = gsm_a_ccch.gsm_a_tmsi
                        else:
                            self.tmsi = ''
                        #if options.imsi == '':
                        #    self.filter_imsi()
                        #elif options.imsi == self.imsi:
                        #    self.filter_imsi()

                    # print(dir(gsm_a_ccch))

                    if hasattr(gsm_a_ccch, "e212.lai.mcc"):
                        # print('mcc=%s' % (repr(gsm_a_ccch.e212_lai_mcc)))
                        self.mcc = gsm_a_ccch.e212_lai_mcc
                    if hasattr(gsm_a_ccch, "e212.lai.mnc"):
                        # print('mnc=%s' % (repr(gsm_a_ccch.e212_lai_mnc)))
                        self.mnc = gsm_a_ccch.e212_lai_mnc
   
                    if hasattr(gsm_a_ccch, "gsm_a_dtap_msg_rr_type"):
                        # print('TEST: %s' % repr(gsm_a_ccch.gsm_a_dtap_msg_rr_type))
                        self.msg_rr_type = int(gsm_a_ccch.gsm_a_dtap_msg_rr_type, 16)
                        # print('TYPE: %d' % self.msg_rr_type)
                        if self.msg_rr_type == 28: # system type 3 - or self.msg_rr_type == 28 #4
                            print('System Info Type 3')
                            # print(str(gsm_a_ccch))
                            return self.get_values()

                elif packet[6].layer_name == 'gsm_a.ccch':
                    gsm_a_ccch = packet[6]
                    if hasattr(gsm_a_ccch, "gsm_a_bssmap_cell_ci"):
                        self.ci = int(gsm_a_ccch.gsm_a_bssmap_cell_ci, 16)
                        self.lac = int(gsm_a_ccch.gsm_a_lac, 16)

    def header(self):
        title = 'waiting for type 3 gsm packet'
        print(title)
        # print ("\033[0;31;48m" + title)

    def get_values(self):
        table_value = None
        if self.mcc != '' and self.mnc != '':
            key=(self.mcc, self.mnc)
            if key in self.lookup_table:
                table_value = self.lookup_table[key]

        return {'ci': self.ci, 'lac': self.lac, 'signal_dbm': self.signal_dbm, 'mcc': self.mcc, 'mnc': self.mnc, 'lookup': table_value}

def main():
    parser = OptionParser(usage="%prog: [options]")
    parser.add_option("-i", "--iface", dest="iface", default="lo", help="Interface (default : lo)")
    parser.add_option("-p", "--port", dest="port", default="4729", type="int", help="Port (default : 4729)")    
    parser.add_option("-m", "--imsi", dest="imsi", default="", type="string", help='IMSI to track (default : None, Example: 123456789101112)')
    parser.add_option("-s", "--save", dest="save", default=None, type="string", help="Save all imsi numbers to sqlite file. (default : None)")
    (options, args) = parser.parse_args()

    imsi = ImsiEvil()
    imsi.header()
    imsi.load_lookup()
    capture = pyshark.LiveCapture(interface=options.iface, bpf_filter="port {} and not icmp and udp".format(options.port))
    values = imsi.get_imsi(capture)
    print(values)

    with open('imsi.json', 'w') as f:
        json.dump(values, f)

    print('exiting..')

if __name__ == "__main__":
	main()
