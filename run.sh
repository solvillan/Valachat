DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
valac --pkg curses --pkg gee-0.8 --pkg gio-2.0 -X -lncurses Valachat.vala Message.vala NetworkHandler.vala
$DIR/Valachat
