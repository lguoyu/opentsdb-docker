#!/bin/bash

export COMPRESSION="NONE"
export HBASE_HOME=/opt/hbase
export TSDB_VERSION="::TSDB_VERSION::"
export JAVA_HOME="::JAVA_HOME::"

TSDB_TABLE=${TSDB_TABLE-'tsdb'}
UID_TABLE=${UID_TABLE-'tsdb-uid'}
TREE_TABLE=${TREE_TABLE-'tsdb-tree'}
META_TABLE=${META_TABLE-'tsdb-meta'}
BLOOMFILTER=${BLOOMFILTER-'ROW'}
# LZO requires lzo2 64bit to be installed + the hadoop-gpl-compression jar.
COMPRESSION=${COMPRESSION-'LZO'}
# All compression codec names are upper case (NONE, LZO, SNAPPY, etc).
COMPRESSION=`echo "$COMPRESSION" | tr a-z A-Z`
# DIFF encoding is very useful for OpenTSDB's case that many small KVs and common prefix.
# This can save a lot of storage space.
DATA_BLOCK_ENCODING=${DATA_BLOCK_ENCODING-'DIFF'}
DATA_BLOCK_ENCODING=`echo "$DATA_BLOCK_ENCODING" | tr a-z A-Z`

case $COMPRESSION in
  (NONE|LZO|GZIP|SNAPPY)  :;;  # Known good.
  (*)
    echo >&2 "warning: compression codec '$COMPRESSION' might not be supported."
    ;;
esac

case $DATA_BLOCK_ENCODING in
  (NONE|PREFIX|DIFF|FAST_DIFF|ROW_INDEX_V1)  :;; # Know good
  (*)
    echo >&2 "warning: encoding '$DATA_BLOCK_ENCODING' might not be supported."
    ;;
esac

# HBase scripts also use a variable named `HBASE_HOME', and having this
# variable in the environment with a value somewhat different from what
# they expect can confuse them in some cases.  So rename the variable.
hbh=$HBASE_HOME
unset HBASE_HOME
exec "$hbh/bin/hbase" shell <<EOF
create '$UID_TABLE',
  {NAME => 'id', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'},
  {NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'}

create '$TSDB_TABLE',
  {NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'}

create '$TREE_TABLE',
  {NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'}

create '$META_TABLE',
  {NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'}
EOF

touch /data/hbase/opentsdb_tables_created.txt
