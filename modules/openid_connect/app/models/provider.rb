module OpenIDConnect
  class Provider
    def self.from_setting(setting_hash)
      setting_hash ||= {}
      (setting_hash["providers"] || []).map do |provider_attributes|
      end
    end
  end
end
