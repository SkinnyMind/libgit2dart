#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint libgit2dart.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'libgit2dart'
  s.version          = '1.2.0'
  s.summary          = 'Dart bindings to libgit2.'
  s.description      = <<-DESC
Dart bindings to libgit2.
                       DESC
  s.homepage         = 'https://github.com/SkinnyMind/libgit2dart'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Aleksey Kulikov' => 'skinny.mind@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.vendored_libraries = 'libgit2-1.5.0.dylib'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
