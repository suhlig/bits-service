# Bits Service

The bits-service is an extraction from existing functionality of the cloud-controller - it encapsulates all “bits operations” into its own, separately scalable service. All “bits operations” comprise buildpacks, droplets, app_stashs, packages and the buildpack_cache. 

## Current API:

POST /buildpacks
GET /buildpacks/:guid
DELETE /buildpacks/:guid

POST /droplets
GET /droplets/:guid
DELETE /droplets/:guid

POST /app_stash/entries
POST /app_stash/matches
POST /app_stash/bundles

POST /packages
GET /packages/:guid
DELETE /packages/:guid

## Supported Backends: 

Currently, only local filesystem and S3 are supported. 


## pipeline

To view the pipeline, go to https://flintstone.ci.cf-app.com

To update the pipeline use `./ci/set-pipeline.sh`

To run the pipeline the following configuration variables needs to be specified at `ci/config.yml`:
```yaml
bosh-target:
bosh-username:
bosh-password:
```

## Documentation

The sequence charts in `docs/` were generated with [websequencediagrams](https://www.websequencediagrams.com/) and can be regenerated with `rake docs/create-app.png` etc.
