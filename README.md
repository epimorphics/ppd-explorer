# Price Paid Data (PPD) Explorer

This is the repo for the HM Land Registry
[PPD explorer](http://landregistry.data.gov.uk/app/ppd),
which allows users to explore the Price Paid linked-data
for England and Wales.

## Running this service

### Production mode

When deployed applications will run behind a reverse proxy.

This enables request to be routed to the appropriate application base on the request path.
In order to simplifiy the proxy configuration we retain the original path where possible.

Thus applications running in `production` mode will do so from a sub-directory i.e `/app/ppd`.

It is expected that any rails application running in `production` mode will set
the `config.relative_url_root` property to this sub-directory within the file
`config/environments/production.rb`.

If need be, `config.relative_url_root` may by overridden by means of the
`RAILS_RELATIVE_URL_ROOT` environment variable, althought this could also
require rebuilding the assets or docker image.

If running more than one application locally ensure that each is listerning on a
separate port. In the case of running local docker images, the required
configuration is captured in the `Makefile` and an image can be run by using

```sh
make image run
```

or, if the image is already built, simply

```sh
make run
```

For rails applications you can start the server locally using the following command:

```sh
rails server -e production -p <port> -b 0.0.0.0
```

To test the running application visit `localhost:<port>/<application path>`.

For information on how to running a proxy to mimic production and run multple services
together see [simple-web-proxy](https://github.com/epimorphics/simple-web-proxy/edit/main/README.md)

## Runtime Configuration environment variables

We use a number of environment variables to determine the runtime behaviour
of the application:

| name                       | description                                                             | default value              |
| -------------------------- | ----------------------------------------------------------------------- | -------------------------- |
| `API_SERVICE_URL`          | The base URL from which data is accessed, including the HTTP scheme eg. | None                       |
|                            | http://localhost:8080 if running a `data-api` service locally           |                            |
|                            | http://data-api:8888  if running a `data-api` docker image locally      |                            |
| `SENTRY_API_KEY`           | The DSN for sending reports to the PPD Sentry account                   | None                       |

### Accessing the API during development

#### Pre-requisites

Developers can run the Docker container that defines the SapiNT API
directly from the AWS Docker registry. To do this, you will need:

- AWS IAM credentials to connect to the HMLR AWS account (see Dave or Andy)
- the ECR credentials helper installed locally (see [here](https://github.com/awslabs/amazon-ecr-credential-helper))
- this line: `"credsStore": "ecr-login"` in `~/.docker/config.json`

It is advisable to run a local docker bridge network to mirror production and development environments.
Running a client application as a docker image from their respective `Makefile`s will set this up 
automatically, but to confirn run

```sh
docker network inspect dnet
```

To create the docker network run
```sh
docker network create dnet
```

#### Running the Data API

To run the Data API as a docker container:

```sh
docker run --network dnet -p 8888:8080 --rm --name data-api \
    -e SERVER_DATASOURCE_ENDPOINT=https://landregistry.data.gov.uk/landregistry/query \
    018852084843.dkr.ecr.eu-west-1.amazonaws.com/epimorphics/lr-data-api/dev:1.0-SNAPSHOT_a5590d2
```
the latest image can be found here [dev](https://github.com/epimorphics/hmlr-ansible-deployment/blob/master/ansible/group_vars/dev/tags.yml) 
and [production](https://github.com/epimorphics/hmlr-ansible-deployment/blob/master/ansible/group_vars/prod/tags.yml).
The full list of versions can be found at [AWS
ECR](https://eu-west-1.console.aws.amazon.com/ecr/repositories/private/018852084843/epimorphics/lr-data-api/dev?region=eu-west-1)

Note: port 8080 should be avoided to allow for a reverse proxy to run on this port.

With this set up, the api service is available on `http://localhost:8888` from the host or `http://data-api:8080`
from inside other docker containers.

To build and a run a new docker image check out the [lr-data-api repository](https://github.com/epimorphics/lr-data-api).
and run
```sh
make image run
```

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

