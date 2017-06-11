#!/bin/sh

ITEMS_LIMIT="${ITEMS_LIMIT:-15}"
ITEM_DELIMITER="${ITEM_DELIMITER:-//}"

_COLS=$(tput cols)

function _print_one_line {
	line=$1
	# dumb but quick
	stripped_line=${line//\\033\[[0-9][0-9];[0-9]m/}
	stripped_line=${stripped_line//\\033\[[0-9][0-9]m/}
	stripped_line=${stripped_line//\\033\[[0-9]m/}
	stripped_line=${stripped_line//\\033\[[0-9];[0-9][0-9]m/}
	len=${#stripped_line}

	if [[ "$len" -gt "$_COLS" ]]; then
		w=$(($_COLS - 3))
		echo "${line:0:$w}...\033[0m"
	else
		echo "$line\033[0m"
	fi
}

function _cleanup {
	tput cnorm
	exit $?
}

function menu {
	if [ -z $1 ]; then 
		echo "Usage: menu.sh <variable_name> <option1> <option2> ..."
		exit 1
	fi
	tput civis
	trap _cleanup INT TERM
	stty -echo

	sel=0
	result_var=$1
	args=("$@")
	args_len=${#args[@]}

	if [ $args_len -le $(($ITEMS_LIMIT + 1)) ]; then
		show_all=1
	else
		show_all=0
	fi

	while true; do
		if [ "$show_all" = "1" ]; then
			items=("${args[@]:1}")
		else
			items=("${args[@]:1:$(($ITEMS_LIMIT + 1))}" "...")
		fi
		items_len=${#items[@]}

		i=0
		for item in "${items[@]}"; do
			if [[ $item == *"${ITEM_DELIMITER}"* ]]; then
				item="${item%%${ITEM_DELIMITER}*} \033[0;36m${item#*${ITEM_DELIMITER}}"
			fi
			if [ "$i" = "$sel" ]; then
				_print_one_line "\033[32;1m❯ ${item}"
			else
				_print_one_line "\033[00;0m  ${item}"
			fi
			i=$(($i+1))
		done

		read -rsn1 char
		case "$char" in
			$'\033')
				read -rsn1 -t 1 char
				if [ $? == 1 ]; then
					tput cnorm
					exit
				fi
				case "$char" in
					$'\033')
						tput cnorm
						exit
					;;
					"[")
						read -rsn1 input
				    	case "$input" in
				    		"A")
								sel=$(( ($sel + $items_len - 1) % items_len ))
								if [ $show_all = 0 ] && [ $(($sel + 1)) = $items_len ]; then
									sel=$(($sel - 1))
								fi
				    		;;
				    		"B")
								sel=$(( ($sel + 1) % items_len ))
								if [ $(($sel + 1)) = $items_len ]; then
									show_all=1
								fi
				        	;;
				        esac
				    ;;
			    esac
			;;
			$'\000')
				selected_item="${items[$sel]}"
				eval $result_var='"'"${selected_item%%${ITEM_DELIMITER}*}"'"'; break
			;;
		esac
		echo "\033[${items_len}A\c"
	done
	stty echo
	tput cnorm
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f menu
else
  menu "${@}"
  exit $?
fi
