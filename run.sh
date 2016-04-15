DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
valac --pkg curses --pkg gee-0.8 -X -lncurses Valachat.vala Message.vala
$DIR/Valachat
