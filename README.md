# Dns::CatalogZone
[![Build Status](https://travis-ci.org/mimuret/dns-catalog_zone.svg?branch=master)](https://travis-ci.org/mimuret/dns-catalog_zone)
[![Coverage Status](https://coveralls.io/repos/github/mimuret/dns-catalog_zone/badge.svg?branch=master)](https://coveralls.io/github/mimuret/dns-catalog_zone?branch=master)

PoC of Catlog zone (draft-muks-dnsop-dns-catalog-zones)
[README in Japanese](https://github.com/mimuret/dns-catalog_zone/blob/master/README.jp.md)  

## supported name server softwares
* NSD4 (default)
* Knot dns
* YADIFA

## Installation

```bash
$ git clone https://github.com/mimuret/dns-catalog_zone
$ cd dns-catalog_zone
$ bundle install --path=vendor/bundle
```

## Usage

+ configuration

make CatalogZone file.

```bash
$ bundle exec catz init
$ cat CatalogZone
```

CatalogZone below
```ruby
setting("catlog.example.jp") do |s|
	s.software="nsd"
	s.source="file"
	s.zonename="catlog.example.jp"
	s.zonefile="/etc/nsd/catlog.example.jp.zone"
end
````

+ make name server config

config output to stdout
```bash
$ bundle exec catz make
```


## Settings attribute
| name | value | default | description |
|:-----------|------------|:------------|:------------|
|zonename|string(domain name)|catlog.example| catlog zone domain name |
|software|string|nsd|software module name|
|source|string|file|source module name|
|output|string|stdout|output module name|

### source modules
#### file module
| name | value | required |
|:-----------|:------------|:------------|
|source|file|true|
|zonefile|path|true|

#### axfr module
| name | value | default |required |
|:-----------|:------------|:------------|:------------|
|source|axfr||true|
|server|ip or hostname||true|
|port|int|53|false|
|tsig|string||false|
|src_address|ip||false|
|timeout|int|30|false|

### software modules
#### nsd module
| name | value | required |
|:-----------|:------------|:------------|
|software|nsd||

#### knot module
| name | value | required |
|:-----------|:------------|:------------|
|software|knot||

#### yadifa module
| name | value | required |
|:-----------|:------------|:------------|
|software|yadifa||

### output modules
#### stdout module
| name | value | required |
|:-----------|:------------|:------------|
|output|stdout||

#### file module
| name | value | required |
|:-----------|:------------|:------------|
|output|file||
|output_path|path|true|

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mimuret/dns-catalog_zone.

OR make Dns::CatalogZone::Provider::(Software) gem


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

