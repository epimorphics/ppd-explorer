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
Instead, we use a JSON API wrapper based on SapiNT. The data API is not
directly addressable from outside the deployment network, so to work with
it in development we need to use SSH.

### Coding standards

Rubocop should always return no errors or warnings.

### Running the tests

```sh
rails -t
```

### Connecting to the data service

The application needs to connect to a data API, based on
[SapiNT](https://github.com/epimorphics/sapi-nt), to provide JSON-API access to
the data in the triple store. The base URL for the data API needs to be passed
as an environment variable `API_SERVICE_URL`. In production deployments, the
`API_SERVICE_URL` will be set by Ansible configuration parameters.

When developing PPD locally, the data API URL still needs to be passed via
the environment. For example:

```sh
API_SERVICE_URL="http://....." rails server
```

To prevent unauthorised access to the API, the data API on deployment servers
is protected so that it can only be accessed from `localhost`. Therefore, when
working on API a developer needs to map access to the API so that it appears
to be coming via localhost on the remote server. We can do this by creating
an ssh tunnel.

#### Setting up an ssh tunnel to access the data service

First, check that you have the right ssh config. You will need a copy of the
`lr.pem` key (available on S3, see the ops team for help getting access),
and the following configuration in `~/.ssh/config`:

```text
Host hmlr-*
    IdentityFile   ~/.ssh/lr.pem
    User           ec2-user
    HostName       %h.epimorphics.net
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host 10.10.10.* hmlr_*
  ProxyJump hmlr-bastion
  IdentityFile  ~/.ssh/lr.pem
  User ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

Next we need to know the hostname of the service that's currently hosting the running
service in the `dev` environment. This will typically be a name like `hmlr-dev-pres_071`,
but the numerical suffix will change as the cluster is periodically updated by the ops
team. There are two ways (at least) that we can get this information:

- using [Sensu](https://sensu-hmlr.epimorphics.net/), using the **entities** tab, or
- using the AWS console, under EC2 instances.

In both cases, you will need credentials to log in to Sensu or AWS. See someone in the
infrastructure team if you need credentials but don't have them.

The remainder of this guide will assume `hmlr_dev_pres_071`, which is correct as of the
time of writing (but may not be by the time you are reading this!)

Check that you can access a server by directly connecting via ssh:

```sh
$ ssh hmlr_dev_pres_071
Warning: Permanently added 'hmlr-bastion.epimorphics.net' (ECDSA) to the list of known hosts.
**Warning**: this is a private system operated by Epimorphics Ltd
Warning: Permanently added 'hmlr_dev_pres_071' (ECDSA) to the list of known hosts.
**Warning**: this is a private system operated by Epimorphics Ltd
$
```

Assuming this succeeds, you can set up an ssh tunnel to map the port where the data
API is running on the remote machine to a convenient port on your computer. The local
port you choose is up to you, but a good choice is port 8080. The data service runs
on port 8081 on the remote service, so the tunnel command is:

```sh
$ ssh -f hmlr_dev_pres_071 -L 8080:localhost:8081 -N
Warning: Permanently added 'hmlr-bastion.epimorphics.net,3.251.30.65' (ECDSA) to the list of known hosts.
**Warning**: this is a private system operated by Epimorphics Ltd
Warning: Permanently added 'hmlr_dev_pres_071' (ECDSA) to the list of known hosts.
**Warning**: this is a private system operated by Epimorphics Ltd
```

If this succeeds, you should be able to see the open port with `lsof`:

```sh
$ lsof -i :8080
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
ssh     71358  ian    3u  IPv6 766085      0t0  TCP ip6-localhost:http-alt (LISTEN)
ssh     71358  ian    6u  IPv4 766086      0t0  TCP localhost:http-alt (LISTEN)
```

**Note:** the SSH tunnel will now be running as a background process. You should remember
to stop it when you no longer require access to the API. A command such as `kill` on
the process ID (PID) listed in the output from `lsof` will suffice:

```sh
$ kill -HUP 71358
```

Assuming there are no errors, you will see no output from this command.

Having set up the SSH tunnel, you can then use `localhost:8080` as the data
service URL to give to the application via the environment:

```sh
$ API_SERVICE_URL=http://localhost:8080 rails server
=> Booting Puma
=> Rails 6.1.3.2 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 5.3.2 (ruby 2.6.6-p146) ("Sweetnighter")
*  Min threads: 5
*  Max threads: 5
*  Environment: development
*          PID: 72553
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

## Deployment

To mimic running the application in a deployed state you can run
`make image` and this will run through the assets precompilation, linting and testing before creating a Docker image. To view the Docker container you can run `make run`

To bypass the need for running locally AWS you can pass a global variable to the command with `ECR=local make image`

You can run `make help` to view a list of other make commands available

### Entrypoint.sh

- The Rails Framework requires certain values to be set as a Global environment variable when starting. To ensure the `RAILS_RELATIVE_URL_ROOT` is only set in one place per application we have added this to the `entrypoint.sh` file along with the `SCRIPT_NAME`.
- The Rails secret is also created here.
- There is a workaround to removing the PID lock of the Rails process in the event of the application crashing and not releasing the process.
- We have to pass the `API_SERVICE_URL` so that it is available in the `entrypoint.sh` or the application will throw an error and exit before starting
