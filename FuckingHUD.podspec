Pod::Spec.new do |s|
  s.name     = 'FuckingHUD'
  s.version  = '0.0.6'
  s.ios.deployment_target = '11.0'
  # s.tvos.deployment_target = '9.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE.txt' }
  s.summary  = 'A clean and lightweight progress HUD for your iOS and tvOS app.'
  s.homepage = 'https://github.com/cszwdy/ProgressHUD'
  s.authors   = { 'Sam Vermette' => 'hello@samvermette.com', 'Tobias Tiemerding' => 'tobias@tiemerding.com' }
  s.source   = { :git => 'https://cszwdy@github.com/cszwdy/ProgressHUD.git', :tag => s.version.to_s }

  s.description = 'SVProgressHUD is a clean and easy-to-use HUD meant to display the progress of an ongoing task on iOS and tvOS. The success and error icons are from Freepik from Flaticon and are licensed under Creative Commons BY 3.0.'

  s.source_files = 'ProgressHUD/ProgressHUD/**/*.{h,swift}'
  # s.framework    = 'QuartzCore'
  s.resources    = 'ProgressHUD/ProgressHUD/**/*.{storyboard,xcassets}'
  s.requires_arc = true
end