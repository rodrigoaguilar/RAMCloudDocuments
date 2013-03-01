Pod::Spec.new do |s|
  s.name         = "RAMCloudDocuments"
  s.version      = "0.0.1"
  s.summary      = "Transparent cloud storage access for bContext app. Supports Dropbox and Google Drive."
  s.homepage     = "http://github.com/rodrigoaguilar/RAMCloudDocuments"
  s.license      = 'MIT'
  s.author       = { "Rodrigo Aguilar" => "rodrigo@rodrigoaguilar.com" }
  s.source       = { :git => "https://github.com/rodrigoaguilar/RAMCloudDocuments.git", :tag => "0.0.1" }
  s.platform     = :ios, '6.0'
  s.source_files = 'RAMCloudDocuments'
  s.frameworks   = 'QuartzCore', 'Security'
  s.requires_arc = true
  s.dependency 'Google-API-Client/Drive'
  s.dependency 'Dropbox-iOS-SDK'
  s.dependency 'MFCache'
  s.dependency 'AFNetworking'
end