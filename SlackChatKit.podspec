Pod::Spec.new do |s|
  s.name         = "SlackChatKit"
  s.version      = "0.0.1"
  s.summary      = "A drop-in replacement of UITableViewController with chat features."
  s.homepage     = "http://github.com/tinyspeck/slack-cocoa-chat-kit"
  s.license      = "MIT (example)"
  s.author       = { "dzenbot" => "ignacio@slack-corp.com" }
  s.platform     = :ios
  s.platform     = :ios, "7.0"
  s.source       = { :git => "http://github.com/tinyspeck/slack-cocoa-chat-kit", :tag => "0.0.1" }

  s.source_files = "Classes", "Source/**/*.{h,m}"
  s.requires_arc = true
end
