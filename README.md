# Price Paid Data (PPD) Explorer

This is the repo for the HM Land Registry [PPD
explorer](http://landregistry.data.gov.uk/app/ppd), which allows users to
explore the Price Paid linked-data for England and Wales.

## Running this service

This application can be run stand-alone as a rails server in `development` mode.
However, when deployed, applications will run behind a reverse proxy.

This enables requests to be routed to the appropriate application base on the
request path. In order to simplifiy the proxy configuration we retain the
original path where possible.

For information on how to running a proxy to mimic production and run multple
services together read through the information in our
[simple-web-proxy](https://github.com/epimorphics/simple-web-proxy/edit/main/README.md)
repository.

If running more than one application locally ensure that each is listerning on a
separate port and separate path. In the case of running local docker images, the
required configuration is captured in the `Makefile` and an image can be run by
using

```sh
make image run
```

or if the image is already built, simply

```sh
make run
```

### Development and Production mode

Applications running in `development` mode default to *not* use a sub-directory
to aid with stand-alone development.

Applications running in `production` mode *do* use a sub-directory i.e.
`/app/ppd`.

In each case this has been achieved by setting `config.relative_url_root`
property to this sub-directory within the file
`config/environments/(development|production).rb`.

If need be, `config.relative_url_root` may by overridden by means of the
`RAILS_RELATIVE_URL_ROOT` environment variable, althought this could also
require rebuilding the assets or docker image.

### Running Rails as a server

For developing rails applications you can start the server locally using the
following command:

```sh
rails server
```

and visit <localhost:3000> in your browser.

To change to using `production` mode use the `-e` option; or to change to a
different port use the `-p` option.

Note: In `production` mode, `SECRET_KEY_BASE` is also required. It is
insufficient to just set this as the value must be exported. e.g.

```sh
export SECRET_KEY_BASE=$(./bin/rails secret)
```

#### Running Rails as a server with a sub-directory via Makefile

```sh
API_SERVICE_URL=<data-api url> RAILS_ENV=<mode> RAILS_RELATIVE_URL_ROOT=/<path> make server
```

The default for `RAILS_ENV` here is `development`.

### Building and Running as a docker container

It can be useful to run the compiled Docker image, that will mirror the
production installation, locally yourself. Assuming you have the [Data API
running](#running-the-data-api-locally), then you can run the Docker
image for the app itself as follows:

```sh
make image run
```

or, if the image is already built, simply

```sh
make run
```

Docker images run in `production` mode.

To test the running application visit `localhost:<port>/<application path>`.

## Runtime Configuration environment variables

We use a number of environment variables to determine the runtime behaviour of
the application:

| name                       | description                                                             | default value              |
| -------------------------- | ----------------------------------------------------------------------- | -------------------------- |
| `API_SERVICE_URL`          | The base URL from which data is accessed, including the HTTP scheme eg. | None                       |
|                            | <http://localhost:8888> if running a `data-api service` locally         |                            |
|                            | <http://data-api:8080>  if running a `data-api docker` image locally    |                            |
| `SECRET_KEY_BASE`          | See [description](https://api.rubyonrails.org/classes/Rails/Application.html#method-i-secret_key_base). | |
|                            | For `development` mode a acceptable value is already configured, in production mode this should be set to the output of `rails secret`. | |
|                            | This is handled automatically when starting a docker container, or the `server` `make` target | |
| `SENTRY_API_KEY`           | The DSN for sending reports to the PPD Sentry account                   | None                       |

### Running the Data API locally

The application connects to the triple store via a `data-api` service.

The easiest way to do this is as a local docker container. The image can be
built from [lr-data-api repository](https://github.com/epimorphics/lr-data-api).
or pulled from Amazon Elastic Container Registry
[ECR](https://eu-west-1.console.aws.amazon.com/ecr/repositories/private/018852084843/epimorphics/lr-data-api/dev?region=eu-west-1)

#### Building and running from [lr-data-api repository](https://github.com/epimorphics/lr-data-api)

To build and a run a new docker image check out the [lr-data-api
repository](https://github.com/epimorphics/lr-data-api) and run

```sh
make image run
```

#### Running an existing [ECR](https://eu-west-1.console.aws.amazon.com/ecr/repositories/private/018852084843/epimorphics/lr-data-api/dev?region=eu-west-1) image

Obtaining an ECR image requires:

- AWS IAM credentials to connect to the HMLR AWS account
- the ECR credentials helper installed locally (see
  [here](https://github.com/awslabs/amazon-ecr-credential-helper))
- Set the contents of your `~/.docker/config.json` file to be:

```sh
{
 "credsStore": "ecr-login"
}
```

This configures the Docker daemon to use the credential helper for all Amazon
ECR registries.

To use a credential helper for a specific ECR registry[^1], create a
`credHelpers` section with the URI of your ECR registry:

```sh
{
  [...]
  "credHelpers": {
    "public.ecr.aws": "ecr-login",
    "018852084843.dkr.ecr.eu-west-1.amazonaws.com": "ecr-login"
  }
}
```

Once you have a local copy of the required image, it is advisable to run a local
docker bridge network to mirror production and development environments.

Running a client application as a docker image from their respective `Makefile`s
will set this up automatically, but to confirm run

```sh
docker network inspect dnet
```

To create the docker network run

```sh
docker network create dnet
```

#### To run the Data API as a docker container

```sh
docker run --network dnet -p 8888:8080 --rm --name data-api \
    -e SERVER_DATASOURCE_ENDPOINT=https://landregistry.data.gov.uk/landregistry/query \
    018852084843.dkr.ecr.eu-west-1.amazonaws.com/epimorphics/lr-data-api/dev:1.0-SNAPSHOT_a5590d2
```

Which then should produce something like:

```text
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v2.2.0.RELEASE)

{"ts":"2022-03-21T16:12:26.585Z","version":"1","logger_name":"com.epimorphics.SapiNtApplicationKt",
"thread_name":"main","level":"INFO","level_value":20000,
"message":"No active profile set, falling back to default profiles: default"}
```

The latest images can be found here for
[dev](https://github.com/epimorphics/hmlr-ansible-deployment/blob/master/ansible/group_vars/dev/tags.yml)
and
[production](https://github.com/epimorphics/hmlr-ansible-deployment/blob/master/ansible/group_vars/prod/tags.yml).

The identity of the Docker image will change periodically so the full list of
versions can be found at [AWS
ECR](https://eu-west-1.console.aws.amazon.com/ecr/repositories/private/018852084843/epimorphics/lr-data-api/dev?region=eu-west-1)

N.B. Port 8080 should be avoided to allow for a reverse proxy to run on this
port.

With this set up, the api service is available on `http://localhost:8888` from
the host or `http://data-api:8080` from inside other docker containers.

## Developer notes

### Coding standards

Rubocop should always return no errors or warnings.

### Running the tests

```sh
rails test
```

### Prometheus monitoring

[Prometheus](https://prometheus.io) is set up to provide metrics on the
`/metrics` endpoint. The following metrics are recorded:

- `api_status` (counter) Response from data API, labelled by response status
  code
- `api_requests` (counter) Count of requests to the data API, labelled by result
  success/failure
- `api_connection_failure` (counter) Could not connect to back-end data API,
  labelled by message
- `api_service_exception` (counter) The response from the back-end data API was
  not processed, labelled by message
- `internal_application_error` (counter) Unexpected events and internal error
  count, labelled by message
- `memory_used_mb` (gauge) Process memory usage in megabytes
- `api_response_times` (histogram) Histogram of response times of successful API
  calls.

Internally, we use ActiveSupport Notifications to emit events which are
monitored and collected by the Prometheus store. Relevant pieces of the app
include:

- `config/initializers/prometheus.rb` Defines the Prometheus counters that the
  app knows about, and registers them in the metrics store (see above)
- `config/initializers/load_notification_subscribers.rb` Some boiler-plate code
  to ensure that all of the notification subscribers are loaded when the app
  starts
- `app/subscribers` Folder where the subscribers to the known ActiveSupport
  notifications are defined. This is where the transform from
  `ActiveSupport::Notification` to Prometheus counter or gauge is performed.

In addition to the metrics we define, there is a collection of standard metrics
provided automatically by the [Ruby Prometheus
client](https://github.com/prometheus/client_ruby)

To test Prometheus when developing locally, there needs to be a Prometheus
server running. Tip for Linux users: do not install the Prometheus apt package.
This starts a locally running daemon with a pre-defined configuration, which is
useful when monitoring the machine on which the server is running. A better
approach for testing Prometheus is to
[download](https://prometheus.io/download/) the server package and run it
locally, with a suitable configuration. A basic config for monitoring a Rails
application is provided in `test/prometheus/dev.yml`.

Using this approach, and assuming you install your local copy of Prometheus into
`~/apps`, a starting command line would be something like:

```sh
~/apps/prometheus/prometheus-2.32.1.linux-amd64/prometheus \
  --config.file=test/prometheus/dev.yml \
  --storage.tsdb.path=./tmp/metrics2
```

Something roughly equivalent should be possible on Windows and Mac as well.

## Issues

Please add issues to the [shared issues
list](https://github.com/epimorphics/hmlr-linked-data/issues)

## Additional Information

### Deployment

The detailed deployment mapping is described in `deployment.yml`. At the time of
writing, using the new infrastructure, the deployment process is as follows:

- commits to the `dev-infrastructure` branch will deploy the dev server
- commits to the `preprod` branch will deploy the pre-production server
- any commit on the `prod` branch will deploy the production server as a new
  release

If the commit is a "new" release, the deployment should be tagged with the same
semantic version number matching the  `BREAKING.FEATURE.PATCH` format, e.g.
`v1.2.3`, the same as should be set in the `/app/lib/version.rb`; also, a short
annotation summarising the updates should be included in the tag as well.

Once the production deployment has been completed and verified, please create a
release on the repository using the same semantic version number. Utilise the
`Generate release notes from commit log` option to create specific notes on the
contained changes as well as the ability to diff agains the previous version.

#### `entrypoint.sh` features

- Workaround to removing the PID lock of the Rails process in the event of the
  application crashing and not releasing the process.
- Guards to ensure the required environment variables are set accordingly and
  trigger the build to fail noisily and log to the system.
- Rails secret creation for `SECRET_KEY_BASE` assignment; see [Runtime
  Configuration environment
  variables](#runtime-configuration-environment-variables).

[^1]: With Docker 1.13.0 or greater, you can configure Docker to use different
credential helpers for different registries.
