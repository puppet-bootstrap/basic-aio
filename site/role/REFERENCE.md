# Reference

<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

### Classes

* [`role::agent`](#roleagent): Agent class
* [`role::puppetserver`](#rolepuppetserver): Puppet server class

### Plans

* [`role`](#role): Build a Puppet server and attach agents

## Classes

### <a name="roleagent"></a>`role::agent`

Agent class

#### Examples

##### 

```puppet
include role::agent
```

### <a name="rolepuppetserver"></a>`role::puppetserver`

Puppet server class

#### Examples

##### 

```puppet
include role::puppetserver
```

## Plans

### <a name="role"></a>`role`

Build a Puppet server and attach agents

#### Parameters

The following parameters are available in the `role` plan:

* [`puppet_release`](#puppet_release)
* [`puppet_version`](#puppet_version)
* [`targets`](#targets)
* [`puppet_target`](#puppet_target)
* [`control_repo`](#control_repo)
* [`choria_user`](#choria_user)

##### <a name="puppet_release"></a>`puppet_release`

Data type: `Integer`

The major version of Puppet to use

##### <a name="puppet_version"></a>`puppet_version`

Data type: `Optional[String]`

The version of puppet-agent to install

Default value: ``undef``

##### <a name="targets"></a>`targets`

Data type: `TargetSpec`

The targets to run on

Default value: `'all'`

##### <a name="puppet_target"></a>`puppet_target`

Data type: `TargetSpec`

The puppet server target

Default value: `'puppet'`

##### <a name="control_repo"></a>`control_repo`

Data type: `Variant[
    Stdlib::HTTPUrl,
    Pattern[/\Afile:\/\/\/([^\n\/\0]+(\/)?)+\z/]
  ]`

URL of the control repo

Default value: `'file:///vagrant/'`

##### <a name="choria_user"></a>`choria_user`

Data type: `Optional[String]`

User name of the demo choria user on the Puppet server

Default value: `'vagrant'`

