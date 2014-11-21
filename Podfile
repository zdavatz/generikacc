platform :ios, "7.0"

pod "AFNetworking", "~> 2.5.0"
#pod "JSONKit", "~> 1.5pre"
pod "JSONKit-NoWarning", "~> 1.2"
pod "ZBarSDK", "~> 1.3.1"

post_install do |installer_representation|
  installer_representation.project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_DIRECT_OBJC_ISA_USAGE'] = 'YES'
    end
  end
end
