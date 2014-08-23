@version = "0.0.1"

Pod::Spec.new do |s|
  s.name         		= "SlackChatKit"
  s.version      		= @version
  s.summary      		= "A drop-in replacement of UITableViewController with chat features."
  s.license      		= "MIT (example)"
  s.author       		= { "dzenbot" => "ignacio@slack-corp.com" }
  s.platform     		= :ios, "7.0"
  s.requires_arc 		= true

  s.header_mappings_dir = 'Source'
  s.source_files 		= "Classes", "Source/Classes/*.{h,m}"
  s.frameworks   		= 'UIKit', 'CoreMotion'

  s.dependency     		'SlackChatKit/Helpers'

  s.subspec 'Helpers' do |he|
    he.source_files     = 'Source/Helpers/*.{h,m}'
  end
end