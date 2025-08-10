Pod::Spec.new do |s|
  s.name             = 'kontext_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Kontext Flutter SDK plugin shim for sound status.'
  s.description      = <<-DESC
Best-effort "soundOn"
  DESC
  s.homepage         = 'https://www.kontext.so/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kontext' => 'dev@kontext.so' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
