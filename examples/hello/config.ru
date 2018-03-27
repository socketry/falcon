#!/usr/bin/env falcon --verbose serve -c

run lambda {|env| [200, {}, ["Hello World"]]} 

