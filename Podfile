source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '15.1'
use_frameworks!

target 'PhotoEditor' do
  pod 'SnapKit', '~> 5.7.1'
end

target 'PhotoEditorTests' do
  inherit! :search_paths
  pod 'SwiftCheck', '~> 0.12.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.1'
    end
  end
end
