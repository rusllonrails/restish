require 'active_model/errors'

module Restish

  # Contains validation errors for +Restish::Model+, recreated from the
  # response body.
  class Errors < ActiveModel::Errors
    def from_hash(error_messages)
      error_messages.each do |attribute, errors|
        errors.each do |error|
          if @base.keys.include?(attribute)
            add(attribute, error) unless self[attribute].include?(error)
          elsif attribute == 'base'
            self[:base] << error
          else
            self[:base] << "#{attribute.humanize} #{error}"
          end
        end
      end
      self[:base].uniq!
    end
  end
end
