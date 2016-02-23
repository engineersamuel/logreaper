## Introduction

Welcome to Log Reaper.  Log Reaper is an adhoc analysis webapp for various logs an emphasis on break/fix and identification of errors and solutions.
When you parse a log you will be presented with a custom tailored view for that particular log type, with automatic solution recommendations, and with targeted analysis.

One key feature of Log Reaper is that your log files are **never** transmitted to any server.  All parsing is done within your browser.
The only pieces of information transmitted to any server is the top ERROR-like log lines are sent to Red Hat to get solution recommendations.

Log types supported:

* JBoss logs
* RHEV logs
* VDSM logs
* Log4j output (including the above and various formats, but not all formats)
* Apache access logs (various formats but not all formats)
* lsof output (list open files)
* /var/log/syslog

## Demo of usage

![Screencast Demo](https://cloud.githubusercontent.com/assets/2019830/13253877/62b798f2-da0c-11e5-8776-22d33b8b3fa1.gif "Screencast demo")


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

    http://localhost:8080/labs/logreaper


## Developing for the Red Hat ecosystem

    npm run dev-server

    node src/server/server-dev-redhat.js

    http://foo.redhat.com/labs/logreaper

You'll need the following in `/etc/hosts` so that your browser is using a redhat.com domain.  https is not necessary, but you can use if you'd like.

    127.0.0.1 localhost, foo.redhat.com prod.foo.redhat.com

You'll also need to setup Apache or Nginx to properly proxy.  See [nginx_osx.conf](../blob/master/config/nginx_osx.conf) for an example nginx configuration for proxying when using foo.redhat.com.

## Building locally

    npm run build
    npm run start-no-rh

## Building for production at Red Hat (OSE)

    npm run build
    npm run start
