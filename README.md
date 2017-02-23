## j4.sh

### USAGE: `./j4.sh LINES MAX_MATCHES [...]`

(Diagnose matchstick AIs)

Give AI winning positions and check if it's move wins

It is assumed that ./matchstick prints the line:

'AI removed $l matches from line $n' after it's move.

All other output is ignored.

moves are selected by first possible, feel free to add a different (eg. full random) move selection function

tag ($NAME $LINES $MAX < $pipe | game > $pipe)3>&1

