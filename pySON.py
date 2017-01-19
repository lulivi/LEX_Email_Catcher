#!/usr/bin/python2.7
# -*- coding: UTF-8 -*-
###############################################################################
# FILENAME :
#   pySON.py
#
# DESCRIPTION :
#   Writes ordered mails in JSON format
#
# AUTHOR :
#   Copyright 2017, Luis Liñán (luislivilla@gmail.com)
#
# REPOSITORY :
#   https://github.com/lulivi/LEX_html_email_catcher
#
# LICENSE :
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation, version 3.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see <http://www.gnu.org/licenses/>
###############################################################################

import sys
import os
import json
import time
from collections import OrderedDict

def get_percentage(key):
    return "{0:.2f}".format(100 * (len(d[key]) / sum))

def open_output(filename = ''):
    if filename != "stdout":
        return open(filename, 'w')
    else: return sys.stdout


n_emails = len(sys.argv)
output = sys.argv[-1]

d = {}

for i in range(0, n_emails - 1):
    email = str(sys.argv[i])
    dom = email.split('@')[-1].split('.')[-2]
    if dom not in d: d[dom] = []
    d[dom].append(email)

sum = 0.0
for (key, value) in d.items(): sum += len(value)

for (key, value) in d.items():
    d["(" + str(len(d[key])) + " - " + str(get_percentage(key)) + "%) " + key] = d[key]
    d.pop(key)

localtime = time.asctime( time.localtime(time.time()) )

with open_output(output) as jfile:
    jfile.write(localtime + '\n\nE-Mails')
    jfile.write(json.dumps(OrderedDict(sorted(d.items(), reverse=True)), indent=2))
