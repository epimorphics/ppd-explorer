# Price Paid Data (PPD) Explorer

This is the repo for the HM Land Registry
[PPD explorer](http://landregistry.data.gov.uk/app/ppd),
which allows users to explore the Price Paid linked-data
for England and Wales.

## Running this service

This application can be run stand-alone as a rails server in `development` mode. 
However, when deployed, applications will run behind a reverse proxy.

This enables request to be routed to the appropriate application base on the request path.
In order to simplifiy the proxy configuration we retain the original path where possible.

For information on how to running a proxy to mimic production and run multple services
together see [simple-web-proxy](https://github.com/epimorphics/simple-web-proxy/edit/main/README.md)

If running more than one application locally ensure that each is listerning on a
separate port and separate path. In the case of running local docker images, the required
configuration is captured in the `Makefile` and an image can be run by using

### Development and Production mode

Applications running in `development` mode default to not use a sub-directory to aid 
stand-alone development.

Applications running in `production` mode default to use a sub-directory i.e `/app/ppd`.

In each case the is achieved by setting `config.relative_url_root` property to this 
sub-directory within the file `config/environments/(development|production).rb`.

If need be, `config.relative_url_root` may by overridden by means of the
`RAILS_RELATIVE_URL_ROOT` environment variable, althought this could also
require rebuilding the assets or docker image.

### Building and Running the docker container

```sh
make image run
```

or, if the image is already built, simply

```sh
make run
```
Docker images run in `production` mode.

### Running Rails as a server

For rails applications you can start the server locally using the following command:

```sh
rails server -e production -p <port>
```

#### Running Rails as a server with a sub-directory

```sh
API_SERVICE_URL=<data-api url> RAILS_ENV=<mode> RAILS_RELATIVE_URL_ROOT=/<path> make server
```
The default for `RAILS_ENV` here is `development`.

Note: In `production` mode, `SECRET_KEY_BASE` is also rquired. It is insufficient to just
set this as the value must be exported. i.e.
```sh
export SECRET_KEY_BASE=$(./bin/rails secret)
```


To test the running application visit `localhost:<port>/{application path}`.

## Runtime Configuration environment variables

We use a number of environment variables to determine the runtime behaviour
of the application:

| name                       | description                                                             | default value              |
| -------------------------- | ----------------------------------------------------------------------- | -------------------------- |
| `API_SERVICE_URL`          | The base URL from which data is accessed, including the HTTP scheme eg. | None                       |
|                            | http://localhost:8888 if running a `data-api service` locally           |                            |
|                            | http://data-api:8080  if running a `data-api docker` image locally      |                            |
| `SECRET_KEY_BASE`          | See [description](https://api.rubyonrails.org/classes/Rails/Application.html#method-i-secret_key_base).
For `development` mode a acceptable value is already configured, in production mode this should be set to the output of `rails secret`.
This is handled automatically when starting a docker container, or the `server` `make` target | |
| `SENTRY_API_KEY`           | The DSN for sending reports to the PPD Sentry account                   | None                       |



### Running the Data API during locally

The application connects to the triple store via a `data-api` service.

The easiest way to do this is as a local docker container. The image can be built from [lr-data-api repository](https://github.com/epimorphics/lr-data-api).
or pulled from Amazon Elastic Container Registry [ECR](https://eu-west-1.console.aws.amazon.com/ecr/repositories/private/018852084843/epimorphics/lr-data-api/dev?region=eu-west-1)

#### Building and running from [lr-data-api repository](https://github.com/epimorphics/lr-data-api)

To build and a run a new docker image check out the [lr-data-api repository](https://github.com/epimorphics/lr-data-api) and run
```sh
make image run
```

#### Running an existing image from

See [here](https://github.com/epimorphics/lr-data-api#Running-an-existing-image) on how to run an
existing image from [ECR](https://eu-west-1.console.aws.amazon.com/ecr/repositories/private/018852084843/epimorphics/lr-data-api/dev?region=eu-west-1)


## Developer notes

### Code overview

PPD is a fairly standard Rails app, albeit that the data
comes from a linked-data triple store via an API. ActiveRecord
is not used for this application.

The app does not interact directly with the triple store.
Instead, we use a simple DSL to send queries to the
[DS API](http://github.com/epimorphics/data-API). DS API uses
the structure of the hypercube, represented as a _data structure
definition_ (DSD), to convert the DSL queries to SPARQL.

### Coding standards

Rubocop should always return no errors or warnings.

### Running the tests

```sh
rails test
```

### Prometheus monitoring

[Prometheus](https://prometheus.io) is set up to provide metrics on the
`/metrics` endpoint. The following metrics are recorded:

- `api_status` (counter)
  Response from data API, labelled by response status code
- `api_requests` (counter)
  Count of requests to the data API, labelled by result success/failure
- `api_connection_failure` (counter)
  Could not connect to back-end data API, labelled by message
- `api_service_exception` (counter)
  The response from the back-end data API was not processed, labelled by message
- `internal_application_error` (counter)
  Unexpected events and internal error count, labelled by message
- `memory_used_mb` (gauge)
  Process memory usage in megabytes
- `api_response_times` (histogram)
  Histogram of response times of successful API calls.

Internally, we use ActiveSupport Notifications to emit events which are
monitored and collected by the Prometheus store. Relevant pieces of the
app include:

- `config/initializers/prometheus.rb`
  Defines the Prometheus counters that the app knows about, and registers them
  in the metrics store (see above)
- `config/initializers/load_notification_subscribers.rb`
  Some boiler-plate code to ensure that all of the notification subscribers
  are loaded when the app starts
- `app/subscribers`
  Folder where the subscribers to the known ActiveSupport notifications are
  defined. This is where the transform from `ActiveSupport::Notification` to
  Prometheus counter or gauge is performed.

In addition to the metrics we define, there is a collection of standard
metrics provided automatically by the
[Ruby Prometheus client](https://github.com/prometheus/client_ruby)

To test Prometheus when developing locally, there needs to be a Prometheus
server running. Tip for Linux users: do not install the Prometheus apt
package. This starts a locally running daemon with a pre-defined
configuration, which is useful when monitoring the machine on which the
server is running. A better approach for testing Prometheus is to
[download](https://prometheus.io/download/) the server package and
run it locally, with a suitable configuration. A basic config for
monitoring a Rails application is provided in `test/prometheus/dev.yml`.

Using this approach, and assuming you install your local copy of
Prometheus into `~/apps`, a starting command line would be something like:

```sh
~/apps/prometheus/prometheus-2.32.1.linux-amd64/prometheus \
  --config.file=test/prometheus/dev.yml \
  --storage.tsdb.path=./tmp/metrics2
```

Something roughly equivalent should be possible on Windows and Mac as well.

