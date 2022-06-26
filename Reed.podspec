#
# Be sure to run `pod lib lint ActiveSQLite.Swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Reed'
  s.version          = '1.2.1'
  s.summary          = 'Reed is a downloader framework for Swift. It is many fetures, stability，fast, ow coupling, easily extended.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Reed is a downloader framework for Swift. It is many fetures, stability，fast, ow coupling, easily extended.
                       DESC

  s.homepage         = 'https://github.com/KevinZhouRafael//Reed'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'taozui' => 'wumingapie@gmail.com' }
  s.source           = { :git => 'https://github.com/KevinZhouRafael/Reed.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.swift_versions = ['5.3']
  s.ios.deployment_target = '10.0'

  s.requires_arc = true
  s.source_files = 'Reed/Classes/**/*.swift'
  

  s.dependency 'CocoaLumberjack/Swift'
  s.dependency 'ReachabilitySwift'

  s.dependency 'ZKORM','0.6.0'
  s.dependency 'ZKCommonCrypto'
end
