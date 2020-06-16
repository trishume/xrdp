#!/bin/sh
set -euo
TIMESTAMP=`date '+%Y-%m-%d-%H:%M:%S'`;

lttng create xrdp --output=/home/tristan/traces/xrdp-${TIMESTAMP}
lttng enable-event --kernel sched_switch,sched_process_fork
lttng enable-event -u -a

# not supported in older lttng
# lttng enable-event --userspace-probe=sdt:/usr/local/lib/librfxencode.so.0:librfxcodec:rfx_compose_message_tileset
# lttng enable-event --userspace-probe=/usr/local/lib/librfxencode.so.0:rfxcodec_encode

# after:
# sudo lttng start
# ... do stuff ...
# sudo lttng destroy
