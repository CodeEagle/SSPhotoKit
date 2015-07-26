#
# Be sure to run `pod lib lint SSPhotoKit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SSPhotoKit"
  s.version          = "0.1.0"
  s.summary          = "A Photo Picker "
  s.description      = <<-DESC
                        A Photo Picker for iOS8 

                       DESC
  s.homepage         = "https://github.com/CodeEagle/SSPhotoKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "CodeEagle" => "stasura@hotmail.com" }
  s.source           = { :git => "https://github.com/CodeEagle/SSPhotoKit.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/_SelfStudio'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Example/Classes/**'
  #s.resource_bundles = {
  #  'SSPhotoKit' => ['Pod/Assets/images.xcassets']
  #}

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Photos', 'AVFoundation'
  s.dependency 'ImagePickerSheetController', '~> 0.1.7'
  s.dependency 'SSImageBrowser','~>0.1.5'
  s.dependency 'AsyncDisplayKit'
end
