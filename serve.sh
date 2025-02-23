#!/bin/bash

set -e

rm -rf makelove-build
makelove lovejs
unzip -o "makelove-build/lovejs/gdi-control-the-environment-lovejs" -d makelove-build/html/
echo "http://localhost:8000/makelove-build/html/gdi-control-the-environment/"
python3 -m http.server
# ruby -run -e httpd . -p 8000