function test() {
  xcodebuild \
  -configuration "Debug" \
  -project HostApp.xcodeproj \
  -scheme HostApp \
  -destination "$1" \
  test
}

function prepareTestProject() {
  git clean -fdx
  mise install tuist@4.20.0
  mise use tuist@4.20.0
  touch Tests.swift
  echo "import ViewTestingProd; @main extension ViewTestingApp {}" > App.swift
  tuist generate --no-open
}

cd HostApp
prepareTestProject
test 'platform=macOS,name=Any Mac'
test 'platform=macOS,varint=Mac Catalyst,name=Any Mac'
test 'platform=iOS Simulator,name=Any iOS Simulator Device'
test 'platform=tvOS Simulator,name=Any tvOS Simulator Device'
test 'platform=watchOS Simulator,name=Any watchOS Simulator Device'
test 'platform=visionOS Simulator,name=Any visionOS Simulator Device'
