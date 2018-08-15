platform :ios, '11.0'
use_frameworks!

target 'Tusk' do
pod 'MastodonKit', :git => 'https://github.com/pcperini/MastodonKit.git', :branch => 'master'
  pod 'ReSwift', '~> 4.0'
  pod 'AlamofireImage', '~> 3.3'
  pod 'AFDateHelper', '~> 4.2'
  pod 'DTCoreText', '~> 1.6'

  target 'TuskTests' do
    inherit! :search_paths
  end

  target 'TuskUITests' do
    inherit! :search_paths
  end

end
