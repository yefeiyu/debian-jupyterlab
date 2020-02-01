#!/bin/bash

set -e

/usr/local/bin/set_root_pw.sh
exec /usr/sbin/sshd -D
