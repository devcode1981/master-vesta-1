# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DrawLotteryStarter do
  # we may want to extract this into a shared example if we use this pattern
  # across all of our service objects
  describe '.start' do
    it 'calls :start on an instance of DrawStarter' do
      draw = instance_spy('draw')
      draw_lottery_starter = mock_draw_lottery_starter(draw: draw)
      described_class.start(draw: draw)
      expect(draw_lottery_starter).to have_received(:start)
    end
  end

  describe '#start' do
    it 'checks to make sure that the draw is in pre-lottery' do
      draw = instance_spy('draw', pre_lottery?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to include('in the pre-lottery phase')
    end

    it 'checks to make sure that the draw has at least one group' do
      draw = instance_spy('draw', groups?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('must have at least one group')
    end

    it 'checks to make sure that the draw has all locked groups' do
      draw = instance_spy('draw', all_groups_locked?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to include('cannot have any unlocked groups')
    end

    it 'checks to make sure that the draw has no ungrouped students' do
      draw = instance_spy('draw', all_students_grouped?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('cannot have any students not in groups')
    end

    it 'checks to make sure that the draw has no undeclared students' do
      draw = instance_spy('draw', all_intents_declared?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('cannot have any students who did not declare intent')
    end

    it 'checks to make sure that there are enough beds for students' do
      draw = instance_spy('draw', enough_beds?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('Draw must have at least one bed per student')
    end

    it 'checks to make sure that there are no contested suites' do
      draw = instance_spy('draw', no_contested_suites?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('any suites in other draws that are in the lottery')
    end

    it 'checks to make sure that all sizes are still available' do
      draw = instance_spy('draw', present?: true, suite_sizes: [1],
                                  group_sizes: [1, 2])
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('all groups must be the size of an available suite')
    end

    # rubocop:disable RSpec/ExampleLength
    it 'disbands groups with an unavailable size' do
      groups = instance_spy('ActiveRecord::Relation')
      draw = instance_spy('draw', present?: true, suite_sizes: [1],
                                  group_sizes: [1, 2], groups: groups)
      allow(groups).to receive(:where).with(size: [2]).and_return(groups)
      described_class.start(draw: draw)
      expect(groups).to have_received(:destroy_all)
    end
    # rubocop:enable RSpec/ExampleLength

    it 'checks to make sure that all groups are locked' do
      draw = instance_spy('draw', all_groups_locked?: false, present?: true)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('cannot have any unlocked groups')
    end

    # rubocop:disable RSpec/ExampleLength
    it 'updates the status of the draw to lottery' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      allow(draw).to receive(:update)
        .with(status: 'lottery', intent_locked: true).and_return(true)
      described_class.start(draw: draw)
      expect(draw).to have_received(:update)
        .with(status: 'lottery', intent_locked: true)
    end
    # rubocop:enable RSpec/ExampleLength

    it 'checks to see if the update works' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      allow(draw).to receive(:update).and_return(false)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to include('Draw update failed')
    end

    it 'returns the updated draw on success' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      result = described_class.start(draw: draw)
      expect(result[:object]).to eq(draw)
    end

    it 'sets the object key to nil in the hash on failure' do
      draw = instance_spy('draw', validity_stubs(valid: false))
      result = described_class.start(draw: draw)
      expect(result[:object]).to be_nil
    end
  end

  def mock_draw_lottery_starter(param_hash)
    instance_spy('draw_lottery_starter').tap do |draw_lottery_starter|
      allow(described_class).to receive(:new).with(param_hash)
        .and_return(draw_lottery_starter)
    end
  end

  def validity_stubs(valid:, **attrs)
    {
      pre_lottery?: valid, groups?: valid, enough_beds?: valid, nil?: !valid,
      all_students_grouped?: valid, no_contested_suites?: valid,
      all_groups_locked?: valid, all_intents_declared?: valid
    }.merge(attrs)
  end
end
