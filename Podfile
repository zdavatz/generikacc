platform :ios, "12.0"

target "Generika" do
  pod "AFNetworking", "~> 4.0"
  pod "NTMonthYearPicker", "~> 1.0"
  pod 'GZIP', '~> 1.3.0'
  pod 'KissXML', '~> 5.3.1'
  pod 'SSZipArchive'

  target "GenerikaTests" do
    inherit! :search_paths
    pod "OCMock", "~> 3.4.1"
  end
end


post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_DIRECT_OBJC_ISA_USAGE'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
