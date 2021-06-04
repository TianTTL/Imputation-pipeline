#!/bin/bash

jid1="$1"
jid2="$2"
jid3="$3"
jid4="$4"
jid5="$5"
jid6="$6"
jid7="$7"

sacct \
    --format="JobId,JobName,AllocCPUS,MaxRSS,State,ExitCode,Elapsed,CPUTime" \
    -j ${jid1},${jid2},${jid3},${jid4},${jid5},${jid6},${jid7}
