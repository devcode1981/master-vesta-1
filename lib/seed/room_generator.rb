# frozen_string_literal: true

# Seed script generator for Rooms
class RoomGenerator
  include Callable

  def initialize(overrides: {})
    @overrides = overrides
  end

  def generate
    RoomCreator.new(gen_params).create![:redirect_object]
  end

  make_callable :generate

  private

  attr_reader :params, :overrides

  def gen_params
    @params ||= { suite: Suite.all.sample || SuiteGenerator.generate,
                  beds: rand(1..2),
                  number: FFaker::Address.building_number }.merge(overrides)
  end
end
