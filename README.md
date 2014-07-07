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

## Running the integration tests

### Launch bosh-lite

Refer to the [Bosh Lite README](https://github.com/cloudfoundry/bosh-lite/blob/master/README.md)
for more information.

### Optionally override dependency locations

```
# The local filesystem path to the downloaded stemcell
$ export STEMCELL_PATH=/path/to/bosh-stemcell-60-warden-boshlite-ubuntu-lucid-go_agent.tgz

# Specify a closer mirror
$ export MIRROR_URL=http://example.com/ubuntu
```

### Run the integration tests

```
$ bundle exec rake spec:integration
```
