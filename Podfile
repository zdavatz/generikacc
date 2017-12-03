platform :ios, "8.0"

target "Generika" do
  pod "AFNetworking", "~> 2.5.0"
  pod "JSONKit-NoWarning", "~> 1.2"
  pod "ZBarSDK", "~> 1.3.1"
  pod "NTMonthYearPicker", "~> 1.0"

  target "GenerikaTests" do
    inherit! :search_paths
    pod "OCMock", "~> 3.4.1"
  end
end


post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_DIRECT_OBJC_ISA_USAGE'] = 'YES'
    end
  end
end
