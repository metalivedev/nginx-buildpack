# Nginx Buildpack

Nginx-buildpack vendors NGINX inside a dyno and connects NGINX to an
app server via UNIX domain sockets.

## Usage

To create an Nginx binary for your PaaS, push this application and it
will compile a new version of nginx for you. Download this version by
visiting your application. This has been successfully built in 128MB.

To use this binary in your appication, refer to this buildpack.

## Requirements

* Your webserver listens to the socket at `/tmp/nginx.socket`.
* You touch `/tmp/app-initialized` when you are ready for traffic.
* You can start your web server with a shell command.

## Features

* Unified NXNG/App Server logs.
* [L2met](https://github.com/ryandotsmith/l2met) friendly NGINX log format.
* [Heroku request ids](https://devcenter.heroku.com/articles/http-request-id) embedded in NGINX logs.
* Crashes dyno if NGINX or App server crashes. Safety first.
* Language/App Server agnostic.
* Customizable NGINX config.
* Application coordinated dyno starts.

### Logging

NGINX will output the following style of logs:

```
measure.nginx.service=0.007 request_id=e2c79e86b3260b9c703756ec93f8a66d
```

You can correlate this id with your Heroku router logs:

```
at=info method=GET path=/ host=salty-earth-7125.herokuapp.com request_id=e2c79e86b3260b9c703756ec93f8a66d fwd="67.180.77.184" dyno=web.1 connect=1ms service=8ms status=200 bytes=21
```

### Language/App Server Agnostic

Nginx-buildpack provides a command named `bin/start-nginx` this
command takes another command as an argument. You must pass your app
server's startup command to `start-nginx`.

For example, to get NGINX and Unicorn up and running:

```bash
$ cat Procfile
web: bin/start-nginx bundle exec unicorn -c config/unicorn.rb
```

### Setting the Worker Processes

You can configure NGINX's `worker_processes` directive via the
`NGINX_WORKERS` environment variable.

For example, to set your `NGINX_WORKERS` to 8 on a PX dyno:

```bash
$ heroku config:set NGINX_WORKERS=8
```

### Customizable NGINX Config

You can provide your own NGINX config by creating a file named
`nginx.conf.erb` in the config directory of your app. Start by copying
the buildpack's [default config
file](https://github.com/ryandotsmith/nginx-buildpack/blob/master/config/nginx.conf.erb).

### Customizable NGINX Compile Options

See [scripts/build_nginx.sh](scripts/build_nginx.sh) for the build
steps. Configuring is as easy as changing the "./configure" options.

### Application/Dyno coordination

The buildpack will not start NGINX until a file has been written to
`/tmp/app-initialized`. Since NGINX binds to the dyno's $PORT and
since the $PORT determines if the app can receive traffic, you can
delay NGINX accepting traffic until your application is ready to
handle it. The examples below show how/when you should write the file
when working with Unicorn.

## Setup

Here are 2 setup examples. One example for a new app, another for an
existing app. In both cases, we are working with ruby & unicorn. Keep
in mind that this buildpack is not ruby specific.

### Existing App

Update Buildpacks
```bash
$ heroku config:set BUILDPACK_URL=https://github.com/ddollar/heroku-buildpack-multi.git
$ echo 'https://github.com/ryandotsmith/nginx-buildpack.git' >> .buildpacks
$ echo 'https://codon-buildpacks.s3.amazonaws.com/buildpacks/heroku/ruby.tgz' >> .buildpacks
$ git add .buildpacks
$ git commit -m 'Add multi-buildpack'
```
Update Procfile:
```
web: bin/start-nginx bundle exec unicorn -c config/unicorn.rb
```
```bash
$ git add Procfile
$ git commit -m 'Update procfile for NGINX buildpack'
```
Update Unicorn Config
```ruby
require 'fileutils'
listen '/tmp/nginx.socket'
before_fork do |server,worker|
	FileUtils.touch('/tmp/app-initialized')
end
```
```bash
$ git add config/unicorn.rb
$ git commit -m 'Update unicorn config to listen on NGINX socket.'
```
Deploy Changes
```bash
$ git push heroku master
```

### New App

```bash
$ mkdir myapp; cd myapp
$ git init
```

**Gemfile**
```ruby
source 'https://rubygems.org'
gem 'unicorn'
```

**config.ru**
```ruby
run Proc.new {[200,{'Content-Type' => 'text/plain'}, ["hello world"]]}
```

**config/unicorn.rb**
```ruby
require 'fileutils'
preload_app true
timeout 5
worker_processes 4
listen '/tmp/nginx.socket', backlog: 1024

before_fork do |server,worker|
	FileUtils.touch('/tmp/app-initialized')
end
```
Install Gems
```bash
$ bundle install
```
Create Procfile
```
web: bin/start-nginx bundle exec unicorn -c config/unicorn.rb
```
Create & Push Heroku App:
```bash
$ heroku create --buildpack https://github.com/ddollar/heroku-buildpack-multi.git
$ echo 'https://codon-buildpacks.s3.amazonaws.com/buildpacks/heroku/ruby.tgz' >> .buildpacks
$ echo 'https://github.com/ryandotsmith/nginx-buildpack.git' >> .buildpacks
$ git add .
$ git commit -am "init"
$ git push heroku master
$ heroku logs -t
```
Visit App
```
$ heroku open
```
