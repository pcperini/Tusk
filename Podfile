platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

target 'Tusk' do
  pod 'MastodonKit', :git => 'https://github.com/pcperini/MastodonKit.git', :branch => 'master', :commit => 'head'
  pod 'ReSwift', '~> 4.0'
  pod 'AlamofireImage', '~> 3.3'
  pod 'AFDateHelper', '~> 4.2'
  pod 'DTCoreText', '~> 1.6'
  pod 'KeychainAccess', '~> 3.1'
  pod 'AnimatedGIFImageSerialization', '~> 0.2'
  pod 'Lightbox', '~> 2.1'
  pod 'MGSwipeTableCell', '~> 1.6'
  pod 'SwiftyBeaver', '~> 1.6'
  pod 'YPImagePicker', '~> 3.4'
  pod 'DeckTransition', '~> 2.0'

  target 'TuskTests' do
    inherit! :search_paths
  end

  target 'TuskUITests' do
    inherit! :search_paths
  end

end
