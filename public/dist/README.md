## Why is this committed ?!

The production instance of Log Reaper is hosted in a limited OpenShift 2.0 within Red Hat.  The default
settings for the gears are not provisioned to handle the resource requirements of the webpack build.
While there may be more elegant solutions pushing the build artifacts will get us to production first,
then we can optimize later.  I'm hoping that once we move to OSE 3.0 there may be a better solution using docker.
