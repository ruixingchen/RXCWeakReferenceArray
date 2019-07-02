Pod::Spec.new do |spec|

  spec.name         = "RXCWeakReferenceArray"
  spec.version      = "1.0"
  spec.summary      = "for multi delegates"
  spec.description  = "for multi delegates"
  spec.homepage     = "https://github.com/ruixingchen/RXCWeakReferenceArray"
  spec.license      = "MIT"

  spec.author       = { "ruixingchen" => "rxc@ruixingchen.com" }
  spec.platform     = :ios, "10.0"

  spec.source       = { :git => "https://github.com/ruixingchen/RXCWeakReferenceArray.git", :tag => spec.version.to_s }
  spec.source_files  = "Source", "Source/**/*.{swift}"
  spec.requires_arc = true

end
