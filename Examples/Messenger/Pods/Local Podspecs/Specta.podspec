Pod::Spec.new do |s|
  s.name     = 'Specta'
  s.version  = '0.3.0.beta1'
  s.license  = 'MIT'
  s.summary  = 'A light-weight TDD / BDD framework for Objective-C & Cocoa.'
  s.homepage = 'http://github.com/specta/specta'
  s.author   = { 'Peter Jihoon Kim' => 'raingrove@gmail.com' }

  s.source   = { :git => 'https://github.com/specta/specta.git', :tag => 'v0.3.0.beta1' }

  s.description = 'Specta is a light-weight testing framework for Objective-C and Cocoa that adds RSpec-like DSL to XCTest.'

  s.source_files = 'Specta/Specta/**/*.{h,m}'

  s.frameworks = 'Foundation', 'XCTest'

  s.requires_arc    = true
  s.osx.xcconfig    = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(DEVELOPER_FRAMEWORKS_DIR) "$(PLATFORM_DIR)/Developer/Library/Frameworks" "$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/Library/Frameworks"' }
  s.ios.xcconfig    = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(DEVELOPER_FRAMEWORKS_DIR) "$(PLATFORM_DIR)/Developer/Library/Frameworks" "$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks"' }
end

