# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Draw, type: :model do
  describe 'basic validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to have_many(:students) }
    it { is_expected.to have_many(:groups) }
    it { is_expected.to have_many(:draws_suites) }
    it { is_expected.to have_many(:suites).through(:draws_suites) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'callbacks' do
    it 'nullifies the draw_id field on users in the draw after destroy' do
      draw = FactoryGirl.create(:draw_with_members)
      students = draw.students
      draw.destroy
      expect(students.map(&:reload).map(&:draw_id).all?(&:nil?)).to be_truthy
    end
    it 'clears old_draw_id when necessary' do
      draw = FactoryGirl.create(:draw)
      student = FactoryGirl.create(:student, old_draw_id: draw.id)
      draw.destroy
      expect(student.reload.old_draw_id).to be_nil
    end
  end

  describe '#suite_sizes' do
    let(:draw) { FactoryGirl.build_stubbed(:draw) }
    it 'returns an array of all the available suite sizes in the draw' do
      instance_spy('SuiteSizesQuery', call: [1, 2]).tap do |q|
        allow(SuiteSizesQuery).to receive(:new).with(draw.suites.available)
          .and_return(q)
      end
      expect(draw.suite_sizes).to match_array([1, 2])
    end
  end

  # this is testing a private method, feel free to remove it if it ever fails
  describe '#student_count' do
    it 'returns the number of students in the draw' do
      students = Array.new(3) { instance_spy('User') }
      draw = FactoryGirl.build_stubbed(:draw)
      allow(draw).to receive(:students).and_return(students)
      expect(draw.send(:student_count)).to eq(3)
    end
  end

  describe '#students?' do
    it 'returns true if the student_count is greater than zero' do
      draw = FactoryGirl.build_stubbed(:draw)
      allow(draw).to receive(:student_count).and_return(1)
      expect(draw.students?).to be_truthy
    end

    it 'returns false if the student_count is zero' do
      draw = FactoryGirl.build_stubbed(:draw)
      allow(draw).to receive(:student_count).and_return(0)
      expect(draw.students?).to be_falsey
    end
  end

  describe '#groups?' do
    it 'returns true if the group_count is greater than zero' do
      draw = FactoryGirl.build_stubbed(:draw)
      allow(draw).to receive(:group_count).and_return(1)
      expect(draw.groups?).to be_truthy
    end

    it 'returns false if the group_count is zero' do
      draw = FactoryGirl.build_stubbed(:draw)
      allow(draw).to receive(:group_count).and_return(0)
      expect(draw.groups?).to be_falsey
    end
  end

  describe '#enough_beds?' do
    it 'returns true if bed_count >= student_count' do
      draw = FactoryGirl.build_stubbed(:draw)
      allow(draw).to receive(:bed_count).and_return(2)
      allow(draw).to receive(:student_count).and_return(1)
      expect(draw.enough_beds?).to be_truthy
    end

    it 'returns false if bed_count < student_count' do
      draw = FactoryGirl.build_stubbed(:draw)
      allow(draw).to receive(:bed_count).and_return(1)
      allow(draw).to receive(:student_count).and_return(2)
      expect(draw.enough_beds?).to be_falsey
    end
  end

  describe '#open_suite_sizes' do
    it 'returns suite sizes in the draw minus locked sizes' do
      draw = FactoryGirl.build_stubbed(:draw, locked_sizes: [1])
      all_sizes = [1, 2]
      allow(draw).to receive(:suite_sizes).and_return(all_sizes)
      expect(draw.open_suite_sizes).to eq([2])
    end
  end

  describe '#bed_count' do
    it 'returns the number of beds across all available suites' do
      draw = FactoryGirl.create(:draw_with_members, suites_count: 2)
      draw.suites.last.update(group_id: 123)
      expect(draw.send(:bed_count)).to eq(draw.suites.first.size)
    end
  end

  describe '#available_suites' do
    it 'returns suites without associated groups' do
      available = FactoryGirl.create(:suite)
      taken = FactoryGirl.create(:locked_group, :with_suite).suite
      draw = FactoryGirl.create(:draw, suites: [available, taken])
      expect(draw.available_suites).to eq([available])
    end
  end

  describe '#ungrouped_students' do
    it 'returns true if there are students in the draw not in a group' do
      draw = FactoryGirl.create(:draw_with_members, students_count: 2)
      FactoryGirl.create(:group, leader: draw.students.first)
      expect(draw.ungrouped_students?).to be_truthy
    end
    it 'returns false if there are no students in the draw not in a group' do
      draw = FactoryGirl.create(:draw_with_members, students_count: 1)
      FactoryGirl.create(:group, leader: draw.students.first)
      expect(draw.ungrouped_students?).to be_falsey
    end
  end

  describe '#all_groups_locked?' do
    it 'returns true if all groups in the draw are locked' do
      draw = FactoryGirl.create(:draw_with_members, students_count: 1)
      FactoryGirl.create(:locked_group, leader: draw.students.first)
      expect(draw.all_groups_locked?).to be_truthy
    end
    it 'returns false if not all groups in the draw are locked' do
      draw = FactoryGirl.create(:draw_with_members, students_count: 2)
      FactoryGirl.create(:locked_group, leader: draw.students.first)
      FactoryGirl.create(:full_group, leader: draw.students.second)
      expect(draw.all_groups_locked?).to be_falsey
    end
  end

  describe '#no_contested_suites?' do
    xit 'returns true if there are no suites contested in other draws'
    xit 'returns false if there are any suites contested in other draws'
  end

  describe '#student_count' do
    xit 'returns the nuber of students in the draw'
  end
end
