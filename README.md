## Introduction

Welcome to Logreaper

## Quickstart for development outside of Red Hat

Install the necessary npm modules

    npm install

In one tab start the webpack-dev-server

    npm run dev-server

In another tab start node

    node src/server/server-dev.js

Access the site

    http://localhost:8080/labs/logreaper


## Developing locally

    npm run dev-server

    node src/server/server-dev.js

## Developing for the Red Hat ecosystem

    npm run dev-server

    node src/server/server-dev-redhat.js

## Building locally

    npm run build
    npm run start-no-rh

## Building for production at Red Hat (OSE)

    npm run build
    npm run start
