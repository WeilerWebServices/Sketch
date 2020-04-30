Pod::Spec.new do |s|
  s.name         = "AFS3Client"
  s.version      = "0.1.1"
  s.summary      = "AFNetworking Client for the Amazon S3 API."
  s.homepage     = "https://github.com/jallen/AFS3Client"
  s.license      = 'MIT'
  s.author       = { "Jared Allen" => "jared@redcact.us" }
  s.source       = { :git => "https://github.com/jallen/AFS3Client", 
                     :tag => "0.1.1" }

  s.source_files = 'AFS3Client'
  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 1.0'
end
