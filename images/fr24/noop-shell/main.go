// noop-shell is installed as /bin/bash in the fr24 image. fr24feed forks itself and execs
// `/bin/bash -c "/bin/netstat -nlt | grep 0.0.0.0:30005 | wc -l"` (is a local decoder listening?)
// and `/usr/bin/pgrep -f fa-mlat-client`. When the exec fails, as on a shell-less distroless image,
// the forked child deadlocks on a lock inherited from fr24feed's other threads instead of exiting,
// and fr24feed waits on its pipe forever. Neither answer matters here (the receiver is given with
// --host, MLAT is off), so this exits 0 with no output and no shell is shipped.
package main

func main() {}
