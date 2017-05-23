# DO NOT USE IN PRODUCTION.  NOT TESTED.

Only meant to work on Debian 8.8 (Jessie).

## Install

On your normal, home machine (eg your laptop):

```sh
git clone https://github.com/sandhawke/mastodon-installer.git
cd mastodon-installer
```

## Configure

It needs to know your personal email address for letsencrypt contact info.

```sh
echo 'your@email.here' > admin_email.txt
```

## Usage

Given a remote server (example.org) to which you can ssh as root:

```sh
./install-on-remote example.org
```

It logs in and installs [mastodon](https://github.com/tootsuite/mastodon).

Takes about 20 minutes, depending (of course) on the speed of the
remote machine.

## Someday

* support non-TLS, for dev

* option for S3

* have a docker version, to be faster; at least a way to not build
  ruby fresh

* a way to upgrade the remote machine

* use the APIs at mailgun, godaddy, digitalocean, etc, to implement a
  version that also allocates the server (or server cluster), and
  maybe the domain name.

* make the local part be node.js, so it's an 'npm install' instead of
  'git clone'

* come up with a more clever name like mastodon-master or
  mastodon-herder
