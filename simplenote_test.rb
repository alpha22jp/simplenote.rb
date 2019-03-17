#!/usr/bin/env ruby
# coding: utf-8
#-------------------------------------------------------------------------------
# simplenote_test.rb
#   Author: alpha22jp@gmail.com
#-------------------------------------------------------------------------------

require 'optparse'
require './simplenote'
require './simplenote_db'

#-------------------------------------------------------------------------------
# Account setting

email = 'abc@example.com'
password = 'password'

#-------------------------------------------------------------------------------
# Show note

def show_note(note)
  create_date = Time.at(note["creationDate"].to_i).strftime('%Y-%m-%d %H:%M:%S')
  modify_date = Time.at(note["modificationDate"].to_i).strftime('%Y-%m-%d %H:%M:%S')
  markdown = note["systemTags"].find { |i| i == "markdown" } ? 1 : 0
  pinned = note["systemTags"].find { |i| i == "pinned" } ? 1 : 0

  puts "----"
  puts "key: #{note["key"]}"
  puts "version:  #{note["version"]}"
  puts "created:  #{create_date}"
  puts "modified: #{modify_date}"
  puts "markdown: #{markdown}, pinned: #{pinned}"
  puts "tags: #{note["tags"]}"
  puts
  puts "#{note["content"]}" if note.key?("content")
end

#-------------------------------------------------------------------------------
# Update all notes

def update_all_notes(server, db, force = false)
  index = server.get_index
  index.each do |item|
    note_db = db.search_note(item["id"])
    next if !force && note_db && item["v"] <= note_db["version"]
    puts "Need to update: #{item["id"]}"
    note = server.get_note(item["id"])
    db.update_note(note)
  end
  puts "Total note count: #{index.count}"
end

#-------------------------------------------------------------------------------
# Show all undeleted notes on server

def show_all_notes(db)
  notes = server.get_index
  notes.each do |note|
    note = server.get_note(note["key"])
    show_note(note)
  end
end

#-------------------------------------------------------------------------------
# Show all undeleted notes on DB

def show_all_notes_db(db)
  db.all_notes.select { |note| !note["deleted"] }
    .each { |note| show_note(note) }
end

#-------------------------------------------------------------------------------
# Main routine

server = Simplenote.new(email, password)
db = SimplenoteDB.new('notes.db')

# update_all_notes(server, db, false)
show_all_notes_db(db)

# note = db.search_note('3c4b6b1c176111e581fcc9023998867e')
# if note == nil
#   puts 'Note not found in DB'
# else
#   note['content'] += "\nHello, world !!!\n"
#   note = server.update_note(note)
#   show_note(note)
# end
