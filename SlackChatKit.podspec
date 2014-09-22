@version = "1.0"

Pod::Spec.new do |s|
  s.name         		= "SlackTextViewController"
  s.version      		= @version
  s.summary      		= "A drop-in UIViewController subclass with a custom growing text input and other useful messaging features. A replacement for UITableViewController & UICollectionViewController."
  s.license      		= "MIT"
  s.author       		= { "Slack Technologies, Inc." => "ios@slack-corp.com" }
    s.source        = { :git => "https://github.com/tinyspeck/SlackTextViewController.git", :tag => "v#{s.version}" }

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
