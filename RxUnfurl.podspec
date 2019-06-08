Pod::Spec.new do |s|
  s.name             = 'RxUnfurl'
  s.version          = '0.1.0'
  s.summary          = 'A reactive extension to generate URL previews.'

  s.description      = <<-DESC
                        A reactive extension to generate URL previews.
                       DESC

  s.homepage         = 'https://github.com/Harry Tran/RxUnfurl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Harry Tran' => 'duchoang.vp@gmail.com' }
  s.source           = { :git => 'https://github.com/Harry Tran/RxUnfurl.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'RxUnfurl/Classes/**/*'

  s.frameworks = 'UIKit'
  s.dependency 'RxSwift'
end
