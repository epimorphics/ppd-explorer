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

    rails -t

## Issues

Please use the [shared issues list](https://github.com/epimorphics/hmlr-linked-data/issues)
