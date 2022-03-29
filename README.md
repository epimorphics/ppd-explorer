# PPD Explorer

This is the repo for the HM Land Registry
[PPD explorer](http://landregistry.data.gov.uk/app/ppd),
which allows users to explore the Price Paid linked-data
for England and Wales.

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

### Accessing the API during development

In deployment, the Rails app will be run in an environment in
which the DS-API is available on `localhost:8080`. In development,
the script `bin/sr-tunnel-daemon` can be used to simulate that
environment, using ssh to proxy the remote dev API onto `localhost`.

### Coding standards

Rubocop should always return no errors or warnings.

### Running the tests

```sh
rails -t
```

## Deployment

To mimic running the application in a deployed state you can run
`make image` and this will run through the assets precompilation, linting and testing before creating a Docker image. To view the Docker container you can run `make run`

To bypass the need for running locally AWS you can pass a global variable to the command with `ECR=local make image`

You can run `make help` to view a list of other make commands available

### entrypoint.sh

This script is used as the main entry point for starting the app from the `Dockerfile`.

The Rails Framework requires certain values to be set as a Global environment variable
when starting. To ensure the `RAILS_RELATIVE_URL_ROOT` is only set in one place per
application we have added this to the `entrypoint.sh` file along with the `SCRIPT_NAME`.
The Rails secret is also created here.

There is a workaround to removing the PID lock of the Rails process in the event of
the application crashing and not releasing the process.

We have to pass the `API_SERVICE_URL` so that it is available in the `entrypoint.sh`
or the application will throw an error and exit before starting

### Prometheus monitoring

[Prometheus](https://prometheus.io) is set up to provide metrics on the
`/metrics` endpoint. The following metrics are recorded:

- `api_status` (counter)
  Response from data API, labelled by response status code
- `api_requests` (counter)
  Count of requests to the data API, labelled by succeeded true/false
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

- `app/lib/prometheus/metrics.rb`
  A central register where metrics can be stored and looked-up subsequently
  by use of a symbol key.
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
