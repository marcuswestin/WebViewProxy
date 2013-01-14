Pod::Spec.new do |s|
  s.name         = "WebViewProxy"
  s.version      = "0.0.1"
  s.summary      = "A standalone iOS class for intercepting requests from a UIWebView."
  s.license      = 'MIT'
  s.author       = { "Marcus Westin" => "narcvs@gmail.com" }
  s.source       = { :git => "https://github.com/marcuswestin/WebViewProxy.git", :commit => "43800bc357fa73febf35bd5174702b5ef490fe93" }
  s.platform     = :ios
  s.homepage	 = 'https://github.com/marcuswestin/WebViewProxy'
  s.source_files = 'WebViewProxy/WebViewProxy.{h,m}'
end