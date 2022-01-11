# polyssh

polyssh (pronounce as 'polish') runs command on multiple remote servers via ssh with friendly TUI.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'polyssh'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install polyssh

## Usage

As CLI:

```
polyssh --ssh-options "-oStrictHostKeyChecking='no'" user1@foo.example.com,user2@bar.example.com ping -c 3 127.0.0.1
```

As library:

```
Polyssh.run(
  ["user1@foo.example.com", "user2@bar.example.com"],
  ["ping", "-c", "3", "127.0.0.1"],
  ssh_options: "-oStrictHostKeyChecking='no'",
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/labocho/polyssh.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
