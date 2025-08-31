module ApplicationCable
  class Channel < ActionCable::Channel::Base
    protected

    def current_user
      connection.current_user
    end

    def authorized_user?(required_role = nil)
      return false unless current_user&.email_verified?
      return true unless required_role

      current_user.role == required_role.to_s
    end

    def log_channel_activity(action, data = {})
      Rails.logger.info "[ActionCable] #{self.class.name} - User: #{current_user&.id} - Action: #{action} - Data: #{data}"
    end
  end
end
