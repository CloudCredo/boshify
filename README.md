# boshify

Boshify generates [BOSH](https://github.com/cloudfoundry/bosh) releases.
Currently it supports generating releases from an Ubuntu source package.

## Example

The following will generate a release that compiles Apache from source:
```
$ boshify -p apache2
```

The release will be generated in your current working directory.

## Deploying

Currently you'll need to create your own deployment manifest.
```
$ bosh -n create release --force
$ bosh -n upload release
$ bosh -n deployment $MANUALLY_CREATED_MANIFEST
$ bosh -n deploy
```

## Use an alternate Ubuntu mirror

```
$ boshify -p postgresql-8.4 -m http://uk.archive.ubuntu.com/ubuntu
```
