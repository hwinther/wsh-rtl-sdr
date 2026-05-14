#!/bin/bash
# Tmux session for GSM monitoring with grgsm_livemon and wireshark

SESSION_NAME="gsm-monitor"

FREQ=${1:-945.4M}
GAIN=${2:-49.6}
SAMPLE_RATE=${3:-3.2M}

tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? != 0 ]; then
    tmux new-session -d -s $SESSION_NAME -n "GSM Monitor"
    
    tmux send-keys -t $SESSION_NAME:0.0 "echo 'Starting grgsm_livemon_headless on frequency $FREQ...'" C-m
    tmux send-keys -t $SESSION_NAME:0.0 "grgsm_livemon_headless -f $FREQ -g $GAIN -s $SAMPLE_RATE" C-m
    
    tmux split-window -h -t $SESSION_NAME:0
    tmux send-keys -t $SESSION_NAME:0.1 "echo 'Starting Termshark to capture GSMTAP...'" C-m
    tmux send-keys -t $SESSION_NAME:0.1 "echo 'Waiting 3 seconds for grgsm_livemon to start...'" C-m
    tmux send-keys -t $SESSION_NAME:0.1 "sleep 3" C-m
    tmux send-keys -t $SESSION_NAME:0.1 "termshark -f udp -Y gsmtap -i lo" C-m
    
    tmux select-layout -t $SESSION_NAME:0 even-horizontal
fi

tmux attach-session -t $SESSION_NAME
