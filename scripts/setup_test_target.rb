#!/usr/bin/env ruby
require 'xcodeproj'

PROJECT = 'GamesWithFriends/GamesWithFriends.xcodeproj'
APP_TARGET = 'GamesWithFriends'
TEST_TARGET = 'GamesWithFriendsTests'
TESTS_DIR = 'GamesWithFriends/GamesWithFriendsTests'

project = Xcodeproj::Project.open(PROJECT)
app = project.targets.find { |t| t.name == APP_TARGET }
raise "App target #{APP_TARGET} not found" unless app

test_target = project.targets.find { |t| t.name == TEST_TARGET }
if test_target.nil?
  test_target = project.new_target(:unit_test_bundle, TEST_TARGET, :ios, '17.0', project.products_group, :swift)
  test_target.add_dependency(app)
  test_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.coreyring.GamesWithFriendsTests'
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/GamesWithFriends.app/GamesWithFriends'
    config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  end
  puts "Created target #{TEST_TARGET}"
else
  puts "Target #{TEST_TARGET} already exists"
end

# Sync all *.swift under the tests dir into the target's compile phase.
group = project.main_group[TEST_TARGET] || project.main_group.new_group(TEST_TARGET, TESTS_DIR)
existing_paths = test_target.source_build_phase.files_references.compact.map(&:real_path).map(&:to_s)
Dir.glob("#{TESTS_DIR}/**/*.swift").sort.each do |path|
  abs = File.expand_path(path)
  next if existing_paths.include?(abs)
  ref = group.find_file_by_path(File.basename(path)) || group.new_file(File.expand_path(path))
  test_target.add_file_references([ref])
  puts "Added #{path}"
end

# Wire the shared scheme's test action to include the test target.
scheme_path = File.join(Xcodeproj::XCScheme.shared_data_dir(PROJECT).to_s, "#{APP_TARGET}.xcscheme")
if File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new(scheme_path)
  already = scheme.test_action.testables.any? do |t|
    t.buildable_references.any? { |b| b.target_name == TEST_TARGET }
  end
  unless already
    scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target))
    scheme.save_as(PROJECT, APP_TARGET, true)
    puts "Wired #{TEST_TARGET} into scheme #{APP_TARGET}"
  end
end

project.save
puts 'Done'
