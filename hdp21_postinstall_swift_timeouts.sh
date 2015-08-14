#!/bin/bash

#
# Enable logging
#
exec >> "/var/log/cbd_postinstall_swift_timeouts.out" 2>&1

#
# Increase Swift timeouts
#
echo -e "[$(date)]   Increasing Swift timeout"
python << END

import sys, os, re

with open(os.path.expanduser("/etc/hadoop/conf/core-site.xml"), 'r') as f:
  core_site = f.read()

new_core_site = re.sub('</configuration>', '  <property>\n    <name>fs.swift.connect.retry.count</name>\n    <value>10</value>\n  </property>\n  <property>\n    <name>fs.swift.socket.timeout</name>\n    <value>150000</value>\n  </property>\n\n</configuration>', core_site)

with open(os.path.expanduser("/etc/hadoop/conf/core-site.xml"), 'w') as f:
  f.write(new_core_site)
END
