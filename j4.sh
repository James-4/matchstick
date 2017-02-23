#!/bin/bash
## stat.sh for  in /home/james.faure/CPE_2016_matchstick
## 
## Made by Jamie Faure
## Login   <james.faure@epitech.net>
## 
## Started on  Wed Feb 22 20:59:14 2017 Jamie Faure
## Last update Thu Feb 23 21:07:44 2017 Jamie Faure
##

## Give AI winning positions and check if it's move wins
## It is assumed that ./matchstick prints the line:
## 'AI removed $l matches from line $n' after it's move.
## All other output is ignored.

NAME=./matchstick

GREEN=$'\e[32m'
RED=$'\e[31m'
NORMAL=$'\e[m'
OK=0
KO=0
pipe=/tmp/mine

trap "rm -f $pipe" EXIT
mkfifo $pipe

usage() { echo USAGE: $0 LINES MAX_MATCHES [...];
	  echo "(Diagnose matchstick AIs)"
	  echo Supplying extra options will disable print_map.
	  echo Use this for maps larger than 50
	  }

say()(echo "$@")>&3

init() {
    for (( i = 0; i < LINES; ++i )) ; do
	(( board[i] = i * 2 + 1 ))
	(( stat ^= (2 * i + 1) % (MAX + 1) ))
    done
}

print_board() {
    (( offset = ${#new[@]} ))
    (( tmp = new[read_line - 1] - read_matches))
    for a in ${!new[@]}; do
	let --offset
	for (( i = 0; i < offset; ++i )); do
	    say -n " "; done
	if (( a == read_line - 1 )); then
	    for (( i = 0; i < tmp; ++i )); do say -n "|"; done
	    if [ $1 -eq 0 ]; then say -n "${GREEN}"; else say -n "${RED}"; fi
	    for (( i = tmp; i < new[a]; ++i )); do say -n "|"; done
	    say -n "${NORMAL}"
	else  
	    for (( i = 0; i < new[a]; ++i )); do
		say -n '|'; done
	fi
	say;
    done
}

take_first() {
    for i in "${!board[@]}"; do
	if [ ${board[$i]} -ne 0 ]; then
	    let ++i
	    line=$i
	    matches=1
	    return 0
	fi
    done
    return 1
}

j4() {
    new=( "${board[@]}" )
    unset save tmp;
    for a in ${!new[@]} ; do
	if (( (new[a] %= (MAX + 1)) > 0 )); then tmp=1;
	elif [ ${board[$a]} -ne 0 ]; then save=$a; fi
    done
    if [ -z tmp ]; then matches=$MAX; (( line = save + 1 )); return 0; fi
    if [ $stat -eq 0 ] ; then
	take_first; (( matches = board[line - 1] % (MAX + 1)));
	if [ $matches -eq 0 ]; then matches=$MAX; fi; return 1; fi
    for a in ${!new[@]} ; do
	if (( new[a] > (new[a] ^ stat) )) ; then
	    (( new[a] -= (matches = new[a] - (new[a] ^ stat)) ))
	    (( line = a + 1 ))
	    break; fi;
    done
    unset count
    for a in ${new[@]} ; do
	if [ $a -gt 0 ] ; then
	    let ++count
	    if [ $a -gt 1 ] ; then
		return 0; fi; fi
    done
    (( matches += new[line - 1] - !(count % 2) + (new[line - 1] == 1) ))
    (( matches += !matches ))
}

read_move() {
    local l
    while [[ ! $l =~ "AI removed" ]]; do
	read l
    done
    read_line=$(echo $l | awk '{print $7}')
    read_matches=$(echo $l | awk '{print $3}')
}

mkmove() {
    echo $1; echo $2
    (( board[$1 - 1] -= $2 ))
    (( stat ^= (board[$1 - 1] + $2) % (MAX + 1 ) ^ board[$1 - 1] % (MAX + 1) ))
}

check_move() {
    read_move
    (( tmp = board[read_line - 1] -= read_matches ))
    if [ $tmp -lt 0 ] || [ $read_matches -gt $MAX ]; then
	say got: $read_line, $read_matches
	say ${RED}AI cheated! ${NORMAL}i no play... "(lel)";
	exit 2; fi
    (( stat ^= (board[read_line - 1] + read_matches) % (MAX + 1) ^ board[read_line - 1] % (MAX + 1) ))
    unset tmp
    for a in ${board[@]}; do
	if (( a % (MAX + 1) == 1 )); then let ++tmp; fi
	if (( a % (MAX + 1) > 1 )); then unset tmp; break; fi;
    done
    if [ $stat -eq 0 ] || (( tmp % 2 == 1 )) ; then
	return 0; else return 1; fi
}

game() {
    init
    while (( 1 )) ; do
	if ! take_first; then break; fi
	mkmove $line $matches
	if ! take_first; then break; fi
	j4; new=( ${board[@]} );
	check_move; verdict=$?;
	if [ ! -z $VERBOSE ]; then print_board $verdict; fi
	say suggestion: line, matches: $line, $matches
	say got: line, matches: $read_line, $read_matches
	if [ $verdict -eq 0 ]; then  let ++OK;
				     if [ -z $VERBOSE ]; then say ${GREEN}OK${NORMAL}; fi
	else let ++KO; if [ -z $VERBOSE ]; then say ${RED}KO${NORMAL};fi
	fi
    done
    say conclusion: ${GREEN}$OK OK${NORMAL}, ${RED}$KO KO${NORMAL};
}

VERBOSE=true
if [ $# -lt 2 ]; then usage; exit 0; 
elif [ $# -gt 2 ]; then unset VERBOSE; fi
LINES=$1; MAX=$2
($NAME $LINES $MAX < $pipe | game > $pipe)3>&1
