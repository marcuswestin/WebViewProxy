Pod::Spec.new do |s|
  s.name         = 'WebViewProxy'
  s.version      = '0.2.5'
  s.summary      = 'A standalone iOS & OSX class for intercepting and proxying HTTP requests (e.g. from a Web View)'
  s.homepage     = 'https://github.com/marcuswestin/WebViewProxy'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'marcuswestin' => 'marcus.westin@gmail.com' }
  s.requires_arc = true
  s.source       = { :git => 'https://github.com/marcuswestin/WebViewProxy.git', :tag => 'v'+s.version.to_s }
  s.platform     = :ios, '5.0'
  s.source_files = 'WebViewProxy/*.{h,m}'
  s.framework    = 'UIKit'
end
