require 'pebblebed'
require_relative 'models/access_group'
require_relative 'models/access_group_subtree'
require_relative 'models/access_group_membership'

class RiverNotifications < ActiveRecord::Observer
  observe :access_group, :access_group_subtree, :access_group_membership

  def self.river
    @river ||= Pebblebed::River.new
  end

  def after_create(record)
    publish(record, :create)
  end

  def after_update(record)
    publish(record, :update)
  end

  def after_destroy(record)
    publish(record, :delete)
  end

  def publish(record, event)
    return if ENV['RACK_ENV'] == 'test'
    self.class.river.publish(:event => event, :uid => record.uid, :attributes => record.attributes)
  end

end
