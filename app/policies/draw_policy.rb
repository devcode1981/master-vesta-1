# frozen_string_literal: true
#
# Class for Draw permissions
class DrawPolicy < ApplicationPolicy
  def show?
    true
  end

  def activate?
    edit? && record.draft?
  end

  def intent_report?
    edit?
  end

  def filter_intent_report?
    intent_report?
  end

  def suite_summary?
    show?
  end

  def suites_edit?
    edit?
  end

  def suites_update?
    suites_edit?
  end

  def student_summary?
    edit?
  end

  def students_update?
    edit?
  end

  def group_actions?
    user.admin? || record.pre_lottery?
  end

  def intent_summary?
    !record.draft?
  end

  def bulk_on_campus?
    edit? && record.before_lottery? && !record.all_intents_declared?
  end

  def oversub_report?
    !record.draft? && !record.suites.empty?
  end

  def group_report?
    oversub_report?
  end

  def start_lottery?
    edit? && record.pre_lottery?
  end

  def oversubscription?
    start_lottery?
  end

  def toggle_size_lock?
    edit?
  end

  def lottery?
    record.lottery? && (user.admin? || user.rep?)
  end

  def start_selection?
    edit? && record.lottery? && record.lottery_complete?
  end

  class Scope < Scope # rubocop:disable Style/Documentation
    def resolve
      scope
    end
  end
end
