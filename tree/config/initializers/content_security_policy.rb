# Be sure to restart your server when you modify this file.

# Only this site may provide scripts, styles, fonts and images. Inline
# <script> and <style> tags need the per-request nonce (javascript_tag
# nonce: true, and the importmap tags add it themselves). Inline style=""
# attributes and on*="" handlers are blocked.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src :self
    policy.style_src :self
    policy.font_src :self
    policy.img_src :self, :data
    policy.connect_src :self
    policy.object_src :none
    policy.base_uri :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # A fresh random nonce per request. Not tied to the session, so public
  # pages don't need a session cookie.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src style-src ]
end
