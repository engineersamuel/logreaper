#!/usr/bin/env bash
gulp coffee
forever stop src/server/server-development.js
forever start -o logs/logreaper.log -e logs/logreaper.log src/server/server-development.js
