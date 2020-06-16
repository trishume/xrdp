#!/bin/bash
set -eu
TIMESTAMP=`date '+%Y-%m-%d-%H:%M:%S'`;

perf buildid-cache --add /usr/local/lib/librfxencode.so.0
perf buildid-cache --add /usr/local/lib/xrdp/libxrdp.so.0
perf buildid-cache --add /usr/lib/xorg/modules/libxorgxrdp.so
perf buildid-cache --add `which xrdp`

perf probe --del 'sdt_librfxcodec:*' || true
perf probe sdt_librfxcodec:rfx_compose_message_tileset_start
perf probe sdt_librfxcodec:rfx_compose_message_tileset_end

perf probe --del 'sdt_libxrdp:*' || true
perf probe sdt_libxrdp:xrdp_rdp_send_fastpath
perf probe sdt_libxrdp:xrdp_rdp_send_fastpath_compratio

perf probe --del 'sdt_xorgxrdp:*' || true
perf probe sdt_xorgxrdp:rdpCapture2
perf probe sdt_xorgxrdp:rdpPutImage

perf probe --del 'probe_librfxencode:*' || true
perf probe -x /usr/local/lib/librfxencode.so.0 'rfxcodec_encode+0'
perf probe -x /usr/local/lib/librfxencode.so.0 'rfxcodec_encode%return'

perf probe --del 'probe_libxrdp:*' || true
perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_fastpath_process_input_event+0'
perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_fastpath_process_input_event%return'
perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'compress_rdp+0'
perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'compress_rdp%return'
# perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_rdp_send_fastpath+0'
perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_rdp_send_fastpath%return'
perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_rdp_send_data+0'
perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_rdp_send_data%return'
# perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_fastpath_send+0'
# perf probe -x /usr/local/lib/xrdp/libxrdp.so.0 'xrdp_fastpath_send%return'

perf probe --del 'probe_libcommon:*' || true
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_tcp_send+0'
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_tcp_send%return'
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_tls_send+0'
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_tls_send%return'
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_set_tls_mode+0'
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_set_tls_mode%return'
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_shutdown_tls_mode+0'
perf probe -x /usr/local/lib/xrdp/libcommon.so.0 'trans_shutdown_tls_mode%return'

perf probe --del 'probe_libxorgxrdp:*' || true
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpCapture+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpCapture%return'
# perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpPutImage+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpPutImage%return'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpClientConAddAllReg+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpClientConAddAllBox+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpClientConAddDirtyScreenBox+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpClientConAddDirtyScreenReg+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpCopyArea+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpCopyArea%return'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpCompositeRects+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpCompositeRects%return'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpPolyFillRect+0'
perf probe -x /usr/lib/xorg/modules/libxorgxrdp.so 'rdpPolyFillRect%return'

# exit 0

DIR=~/perf/xrdp-${TIMESTAMP}
echo $DIR
mkdir $DIR
cd $DIR

ctrl_c() {
  echo "cleaning up"
  rm ~/perf/latest
  ln -s $DIR ~/perf/latest
  chown -R $SUDO_USER ~/perf
  exit
}

trap ctrl_c INT TERM

perf record -e 'sdt_librfxcodec:*,sdt_libxrdp:*,sdt_xorgxrdp:*,probe_librfxencode:*,probe_libxrdp:*,probe_libxorgxrdp:*,probe_libcommon:*,sched:sched_switch' -a
