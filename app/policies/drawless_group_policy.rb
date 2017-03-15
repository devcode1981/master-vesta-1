# frozen_string_literal: true
#
# Policy for permissions on special (non-draw) housing groups
class DrawlessGroupPolicy < ApplicationPolicy
  delegate :lock?, :unlock?, to: :group_policy

  def select_suite?
    user.admin? && record.locked?
  end

  def show?
    record.members.include?(user) || super
  end

  private

  def group_policy
    Pundit.policy!(user, record)
  end
end
