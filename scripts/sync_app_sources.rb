#!/usr/bin/env ruby
# Registers app-target Swift sources under the CastingDirector ClueGeneration folder.
# Idempotent: only adds files not already in the app target's compile phase.
require 'xcodeproj'

PROJECT = 'GamesWithFriends/GamesWithFriends.xcodeproj'
APP_TARGET = 'GamesWithFriends'
# Path relative to repo root:
SOURCE_DIR = 'GamesWithFriends/Features/CastingDirector/Services/ClueGeneration'
# Group subpath relative to the project's main group (the project dir is GamesWithFriends/):
GROUP_SUBPATH = 'Features/CastingDirector/Services/ClueGeneration'

project = Xcodeproj::Project.open(PROJECT)
app = project.targets.find { |t| t.name == APP_TARGET }
raise "App target #{APP_TARGET} not found" unless app

group = project.main_group.find_subpath(GROUP_SUBPATH, true)
existing = app.source_build_phase.files_references.compact.map { |r| r.real_path.to_s }

added = 0
Dir.glob("#{SOURCE_DIR}/**/*.swift").sort.each do |path|
  abs = File.expand_path(path)
  next if existing.include?(abs)
  ref = group.new_file(abs)
  app.add_file_references([ref])
  puts "Added to app target: #{path}"
  added += 1
end

project.save
puts "sync_app_sources: added #{added} file(s)"
