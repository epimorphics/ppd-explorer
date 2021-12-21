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

## Deployment

To mimic running the application in a deployed state you can run
`make image` and this will run through the assets precompilation, linting and testing before creating a Docker image. To view the Docker container you can run `make run`

To bypass the need for running locally AWS you can pass a global variable to the command with `ECR=local make image`

You can run `make help` to view a list of other make commands available

## Entrypoint.sh

* The Rails Framework requires certain values to be set as a Global environment variable when starting. To ensure the `RAILS_RELATIVE_URL_ROOT` is only set in one place per application we have added this to the Entrypoint file along with the `SCRIPT_NAME`.
* The Rails secret is also created here.
* There is a workaround to removing the PID lock of the Rails process in the event of the application crashing and not releasing the process.
* We have to pass the `API_SERVICE_URL` so that it is available in the Entrypoint.sh or the application will throw an error and exit before starting

### Coding standards

Rubocop should always return no errors or warnings.

### Running the tests

    rails -t
