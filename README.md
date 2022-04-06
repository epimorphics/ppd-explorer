# Price Paid Data (PPD) Explorer

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

The back-end data API for PPD is a SapiNT instance, running in its own
Kubernetes pod. For operations reasons, it is not possible to access that pod
from outside the cluster, which means there is no easy way to use the cluster
to provide a dev API to use with a locally running instance of the application
during development. Previously, we have used ssh tunnels to proxy the remote
API onto `localhost`, but this is not a secure or recommended practice.

Instead, developers can run the Docker container that defines the SapiNT API
directly from the AWS Docker registry. To do this, you will need:

- AWS IAM credentials to connect to the HMLR AWS account (see Dave or Andy)
- the ECR credentials helper installed locally (see [here](https://github.com/awslabs/amazon-ecr-credential-helper))
- this line: `"credsStore": "ecr-login"` in `~/.docker/config.json`

With this set up, you should be able to run the container, mapped to
`localhost:8080` using:

```sh
$ AWS_PROFILE=hmlr \
docker run \
-e SERVER_DATASOURCE_ENDPOINT=http://hmlr-dev-pres.epimorphics.net/landregistry/query \
-p 8080:8080 \
018852084843.dkr.ecr.eu-west-1.amazonaws.com/epimorphics/lr-data-api/dev:1.0-SNAPSHOT_a5590d2
```

Which should produce something like:

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

Note that the identity of the Docker image will change periodically. The
currently deployed dev api image version is given by the `api` tag in the ansible
[dev configuration](https://github.com/epimorphics/hmlr-ansible-deployment/blob/master/ansible/group_vars/dev/tags.yml).

If you need to run a different API version then the easiest route to
discovering the most recent is to use the [AWS
ECR](https://eu-west-1.console.aws.amazon.com/ecr/repositories/private/018852084843/epimorphics/lr-data-api/dev?region=eu-west-1)
console or look at the hash to the relevant commit in
[lr-data-api](https://github.com/epimorphics/lr-data-api).

### Coding standards

Rubocop should always return no errors or warnings.

### Running the tests

```sh
rails test
```

## Deployment

To mimic running the application in a deployed state you can run `make image`
and this will run through the assets precompilation, linting and testing before
creating a Docker image. To preview the Docker container you can run `make run`

The automated deployment is managed by `deployment.yaml`. At the time of
writing, the following deployment patterns are defined:

- git tag matching `vNNN`, e.g. `v1.2.3`<br />
  Automatically deployed to the production environment
- git branch `dev-infrastructure`<br />
  Automatically deployed to the dev environment.

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

## Configuration environment variables

We use a number of environment variables to determine the runtime behaviour
of the application:

| name                       | description                                                          | typical value                                    |
| -------------------------- | -------------------------------------------------------------------- | ------------------------------------------------ |
| `RAILS_RELATIVE_URL_ROOT`  | The path from the server root to the application                     | `/app/ppd`                                       |
| `API_SERVICE_URL`          | The base URL from which data is accessed, including the HTTP scheme  | `http://localhost:8080`                          |
