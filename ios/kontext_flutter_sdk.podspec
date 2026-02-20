Pod::Spec.new do |s|
  s.name             = 'kontext_flutter_sdk'
  s.version          = '2.2.0'
  s.summary          = 'Kontext Flutter SDK plugin.'
  s.description      = <<-DESC
Kontext Flutter SDK: sound status, app info, hardware, power, network, etc.
  DESC
  s.homepage         = 'https://www.kontext.so/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kontext' => 'support@kontext.so' }
  s.source           = { :path => '.' }

  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency          'Flutter'
  s.platform            = :ios, '12.0'
  s.swift_version       = '5.0'

  s.frameworks = 'AVFoundation', 'SystemConfiguration', 'CoreTelephony', 'WebKit', 'AdSupport', 'AppTrackingTransparency'

  s.resources = ['PrivacyInfo.xcprivacy']

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
