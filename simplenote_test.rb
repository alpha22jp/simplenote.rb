#!/usr/bin/env ruby
# coding: UTF-8
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
  create_date = Time.at(note['createdate'].to_i).strftime('%Y-%m-%d %H:%M:%S')
  modify_date = Time.at(note['modifydate'].to_i).strftime('%Y-%m-%d %H:%M:%S')
  markdown = note['systemtags'].find { |i| i == 'markdown' } ? 1 : 0
  pinned = note['systemtags'].find { |i| i == 'pinned' } ? 1 : 0

  puts '----'
  puts "Key: #{note['key']}"
  puts "Deleted: #{note['deleted']}: Version: #{note['version']} SyncNum: #{note['syncnum']}"
  puts "Create date: #{create_date}"
  puts "Modify date: #{modify_date}"
  puts "Markdown: #{markdown}, Pinned: #{pinned}"
  puts "Tags: #{note['tags']}"
  puts
  puts "#{note['content']}" if note.key?('content')
end

#-------------------------------------------------------------------------------
# Update all notes

def update_all_notes(server, db, force = false)
  notes = server.get_index
  notes.each do |note|
    note_db = db.search_note(note['key'])
    next if !force && note_db && note['syncnum'].to_i <= note_db['syncnum'].to_i
    puts "Need to update #{note['key']}"
    note = server.get_note(note['key'])
    db.update_note(note)
  end
  puts "Total note count: #{notes.count}"
end

#-------------------------------------------------------------------------------
# Show all undeleted notes on server

def show_all_notes(db)
  notes = server.get_index
  notes.each do |note|
    note = server.get_note(note['key'])
    show_note(note)
  end
end

#-------------------------------------------------------------------------------
# Show all undeleted notes on DB

def show_all_notes_db(db)
  db.all_notes.select { |note| note['deleted'] == 0 }
    .each { |note| show_note(note) }
end

#-------------------------------------------------------------------------------
# Main routine

server = Simplenote.new(email, password)
db = SimplenoteDB.new('notes.db')

update_all_notes(server, db, false)
show_all_notes_db(db)

# note = db.search_note('3c4b6b1c176111e581fcc9023998867e')
# if note == nil
#   puts 'Note not found in DB'
# else
#   note['content'] += "\nHello, world !!!\n"
#   note = server.update_note(note)
#   show_note(note)
# end
