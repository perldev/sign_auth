#!/bin/sh

curl -k   -i -H "api-sign: af24457460e98f04ce5007898fdb6e05654ffe1ee5a6698b017574b12c0a97f9"  --data "hehe" -v http://127.0.0.1:8078/app/check
