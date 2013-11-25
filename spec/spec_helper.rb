require 'active_record'
require 'activerecord-rescue_from_duplicate'

begin
  require 'pry'
  require 'pry-debugger'
rescue LoadError
end

require 'simplecov'
require 'coveralls'

# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
#   SimpleCov::Formatter::HTMLFormatter,
#   Coveralls::SimpleCov::Formatter
# ]
# SimpleCov.start


module RescueFromDuplicate
  class Base
    cattr_accessor :exception

    def create_or_update(*params)
      raise self.class.exception if self.class.exception
    end
  end

  class Rescuable < Base
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::AttributeMethods
    include RescueFromDuplicate::ActiveRecord::Extension

    define_attribute_methods ['name']
    attr_accessor :name

    def self.table_name
      "rescuable"
    end

    def read_attribute_for_validation(attribute)
      send(attribute)
    end

    def _validators
      self.class._validators
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def self._validators
      @validators ||= {
        :name =>
        [
          uniqueness_validator,
          presence_validator
        ]
      }
    end

    def self.uniqueness_validator
      @uniqueness_validator ||= ::ActiveRecord::Validations::UniquenessValidator.new(
        :attributes => [:name],
        :case_sensitive => true, :scope => [:shop_id, :type],
        :rescue_from_duplicate => true
      ).tap { |o| o.setup(self) if o.respond_to?(:setup) }
    end

    def self.uniqueness_validator_without_rescue
      @uniqueness_validator_without_rescue ||= ::ActiveRecord::Validations::UniquenessValidator.new(
        :attributes => [:name],
        :case_sensitive => true, :scope => [:shop_id, :type]
      ).tap { |o| o.setup(self) if o.respond_to?(:setup) }
    end

    def self.presence_validator
      @presence_validator ||= ActiveModel::Validations::PresenceValidator.new(:attributes => [:name])
    end

    def self.index
      @index ||= ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(
        "rescuable",
        "index_rescuable_on_shop_id_and_type_and_name",
        true,
        ["shop_id", "type", "name"],
        [nil, nil, nil],
        nil
      )
    end
  end
end

I18n.t(:prime)
I18n.backend.send(:translations)[:en][:errors][:messages][:taken] = "has already been taken"
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
