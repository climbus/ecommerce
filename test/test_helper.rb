ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

class FakeEventStore
  def initialize
    @events = []
    @published = []
  end

  attr_reader :events, :published

  def publish_event(event, aggregate_id)
    events << event
    published << event
  end

  def read_all_events(aggregate_id)
    events
  end
end

class FakeNumberGenerator
  def call
    "123/08/2015"
  end
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  include Command::Execute

  def arrange(event_store, events)
    event_store.events.concat(Array.wrap(events))
  end

  def act(event_store, command)
    execute(command, **dependencies(event_store))
  end

  def assert_changes(event_store, expected)
    actuals = event_store.published.map(&:data)
    expects = Array.wrap(expected).map(&:data)
    assert_equal(actuals, expects)
  end

  def assert_no_changes(event_store)
    assert_empty(event_store.published)
  end

  private
  def dependencies(event_store)
    {
      repository:       RailsEventStore::Repositories::AggregateRepository.new(event_store),
      number_generator: FakeNumberGenerator.new
    }
  end
end
