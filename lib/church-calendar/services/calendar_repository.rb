require 'yaml'

module ChurchCalendar
  class CalendarRepository
    extend Forwardable

    def initialize(config, data_path)
      @calendars = config
      @path = data_path
    end

    def self.load_from(yaml_config_path, data_path)
      new YAML.load_file(yaml_config_path), data_path
    end

    def [](key)
      unless has_key? key
        raise KeyError.new(key)
      end

      CalendarFacade.new get_calendar_factory(key), metadata(key)
    end

    # returns a CalendarFactory creating Calendars
    # with a specified Sanctorale
    def get_calendar_factory(key)
      sanctorale = CalendariumRomanum::SanctoraleFactory
                   .load_layered_from_files *data_files(key)
      CalendarFactory.new sanctorale
    end

    # list of available calendars
    def keys
      @calendars.keys
    end

    def has_key?(key)
      @calendars.has_key? key
    end

    # Array of data files for the given calendar;
    # should be loaded over each other in the given order
    def data_files(key)
      calendar_setup = @calendars[key]
      raise UnknownCalendarError.new(key) if calendar_setup.nil?

      calendar_setup['files'].collect do |f|
        File.join @path, f
      end
    end

    # metadata for the given calendar -
    # or for all if calendar key not specified
    def metadata(key=nil)
      if key.nil?
        # return Hash {key: metadata(key)}
        return keys.inject({}) {|memo, (k, v)| memo[k] = metadata k; memo}
      end

      m = @calendars[key].dup
      m.delete 'files'
      return m
    end
  end

  class UnknownCalendarError < RuntimeError
    def initialize(key)
      super("Unknown calendar #{key.inspect}")
    end
  end
end
