#!/bin/sh
set -e

cd ext
[ -f Makefile ] && make clean
ruby extconf.rb
make
cd ..

bundle check
export RUBYOPT="-I."

ruby server.rb &
export PID=$!

trap cleanup SIGINT SIGTERM
cleanup() {
  kill $PID
  wait $PID || true
}

trace() {
  echo ------------------------------------------
  echo ./bin/rbtrace -p $PID $*
  echo ------------------------------------------
  ./bin/rbtrace -p $PID -r 3 $* &
  sleep 2
  kill $!
  wait $! || true
  echo
}

trace -m Test.run --devmode
trace -m sleep
trace -m sleep Dir.chdir Dir.pwd Process.pid "String#gsub" "String#*"
trace -m "Kernel#"
trace -m "String#gsub(self,@test)" "String#*(self,__source__)" "String#multiply_vowels(self,self.length,num)"
trace --gc --slow=200
trace --gc -m Dir.
trace --slow=250
trace --slow=250 -m sleep
trace --firehose

cleanup
