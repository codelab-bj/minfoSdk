Pod::Spec.new do |s|
  s.name             = 'minfo_sdk'
  s.version          = '2.3.0'
  s.summary          = 'Minfo SDK with AudioQR detection'
  s.description      = <<-DESC
Minfo SDK with native AudioQR detection using Cifrasoft libraries.
                       DESC
  s.homepage         = 'http://minfo.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Minfo' => 'contact@minfo.com' }
  s.source           = { :path => '.' }
  
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/SCSManagerWrapper.h', 'Classes/minfo_sdk.h'
  
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.ios.deployment_target = '12.0'

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '-ObjC',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  
  s.swift_version = '5.0'
  s.resource_bundles = {'minfo_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
