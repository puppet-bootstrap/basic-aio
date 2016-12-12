# Overview

This project uses [serverspec](serverspec.org) for testing. All test should pass after issuing a `vagrant up` command. The [bundler](bundler.io) project is used to manage the testing environment. 

# Setup

## Fedora 25

### Initial Setup

On a Fedora 25 system, beyond vagrant, only the bundler package needs to be installed.

```
$ sudo dnf install -y rubygem-bundler
```

Make sure `~/bin` is on your path.

```
$ export PATH=$PATH:~/bin
```

Install the required gems.

```
$ bundle install
```

### Running Tests

Once the bundle has been installed and the puppet server is running in Vagrant, run the tests

```
$ rake spec

< snip>

Finished in 1.44 seconds (files took 2.2 seconds to load)
27 examples, 0 failures
```
