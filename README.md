# SimplenoteRuby

Ruby library to interact with [Simplenote](https://app.simmplenote.com/) just like Python library [simplenote.py](https://github.com/mrtazz/simplenote.py).

## Installation

Install via gem:

    $ gem install simplenote_ruby

## Usage

First of all, authenticate user and create simplenote object.
``` ruby
import 'simplenote_ruby'
user = "foo@example.com"
password = "abcdef"
sn = Simplenote.new(user, password)
```

Get all notes:
``` ruby
index = sn.get_index
index.each do |item|
  note = sn.get_note(note["key"])
  puts "key: #{note["key"]}"
  puts "#{note["content"]}" if note.key?("content")
end
```

Update note:
``` ruby
note["content"] = "Test. Test."
sn.update_note(note)
```

Create note from text:
``` ruby
sn.create_note("New_note. Test. Test.")
```

Trash note:
``` ruby
sn.trash_note(note)
```

Delete note:
``` ruby
sn.delete_note(note)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alpha22jp/simplenote.rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/alpha22jp/simplenote.rb/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SimplenoteGem project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alpha22jp/simplenote.rb/blob/master/CODE_OF_CONDUCT.md).
