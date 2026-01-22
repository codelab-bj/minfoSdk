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
  
  s.source_files = 'Classes/**/*', 'Frameworks/*.h'
  s.public_header_files = 'Frameworks/*.h'
  s.vendored_libraries = 'Frameworks/SCSTB_LibraryU.a'
  
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.ios.deployment_target = '12.0'

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '-ObjC'
  }
  
  s.swift_version = '5.0'
  s.resource_bundles = {'minfo_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
