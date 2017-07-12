# Dns::CatalogZone::Daemon
PoC of Catlog zone (draft-muks-dnsop-dns-catalog-zones)

## Installation

```bash
$ git clone https://github.com/mimuret/dns-catalog_zone-daemon
$ cd dns-catalog_zone-daemon
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
	s.zonename="catlog.example.jp"
	s.source="axfr"
	s.server="ns.example.jp"
end
````

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

