# Hugs

Hugs net-http-persistent with convenient delete, get, head, post, and put methods.
Automatically parses JSON and XML responses.

## Why?

Opted to write this gem for a few reasons:

* [Ganeti's API](http://docs.ganeti.org/ganeti/2.2/html/rapi.html), required
  the sending of a message body with the HTTP Get request, which
  [rest-client](https://github.com/archiloque/rest-client) does not allow.
* A [fast](http://blog.segment7.net/articles/2010/05/07/net-http-is-not-slow),
  thread-safe, and persistent client.
* [Excon](https://github.com/geemus/excon) does most everything right, <del>but is not
  compatible with [VCR](https://github.com/myronmarston/vcr) (more specifically
  [webmock](https://github.com/bblimke/webmock) and [fakeweb](https://github.com/chrisk/fakeweb))</del>.
  There looks to be [work on this front](https://github.com/geemus/excon/issues#issue/29).
* Continued learning.

## Opinionated

Intended for but not limited to, endpoints that return JSON or XML.

## Usage

### Bundler

    gem "hugs"

### Examples

See the 'Examples' section in the [wiki](http://github.com/retr0h/hugs/wiki/).

## Compatability

ruby 1.9.2

## Testing

Tests can run offline thanks to [webmock](https://github.com/bblimke/webmock).

    $ bundle exec rake
