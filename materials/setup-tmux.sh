#!/bin/bash

cat << 'EOF' > $HOME/.tmux.conf
set -g mouse on
set -g mode-keys vi
set -g history-limit 50000
set -s escape-time 50
bind-key b previous-window
bind-key = split-window -c '#{pane_current_path}'
bind-key "\"" split-window -c "#{pane_current_path}" -h
bind-key e select-layout even-horizontal
bind-key E select-layout even-vertical
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
bind-key -n C-w if-shell "$is_vim" "send-keys C-\\" "select-pane -l"
EOF

