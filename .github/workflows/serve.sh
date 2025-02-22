#!/bin/bash

set -e

rm -rf makelove-build
makelove lovejs
unzip -o "makelove-build/lovejs/game-name-goes-here-lovejs" -d makelove-build/html/
echo "http://localhost:8000/makelove-build/html/game-name-goes-here/"
python3 -m http.server
# ruby -run -e httpd . -p 8000