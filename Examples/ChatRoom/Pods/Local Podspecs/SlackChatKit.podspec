@version = "1.0"

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
  s.frameworks   		= 'UIKit'

  s.dependency     		'SlackChatKit/Additions'

  s.subspec 'Additions' do |he|
    he.source_files     = 'Source/Additions/*.{h,m}'
  end
end