#!/bin/sh
kal -s GSM900 -g 49.6 > kal.out
cat kal.out | grep chan: | sed -r 's/^.*\(([0-9]+\.[0-9]M)Hz.*$/\1/' > scan.out
