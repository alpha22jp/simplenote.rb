#!/usr/bin/env ruby
# coding: UTF-8
#-------------------------------------------------------------------------------
# simplenote_db.rb
#   Author: alpha22jp@gmail.com
#-------------------------------------------------------------------------------

require 'sqlite3'

#-------------------------------------------------------------------------------
# Database to store Simplenote note

class SimplenoteDB
  def initialize(db_file)
    @db = SQLite3::Database.new(db_file)
    @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS notes
        (key TEXT, deleted INTEGER,
         version INTEGER, syncnum INTEGER,
         createdate TEXT, modifydate TEXT,
         systemtags TEXT, tags TEXT,
         content TEXT)
        SQL
  end

  def add_note(note)
    mapping = {
      key: note['key'], deleted: note['deleted'],
      version: note['version'], syncnum: note['syncnum'],
      createdate: note['createdate'], modifydate: note['modifydate'],
      systemtags: note['systemtags'].join(' '),
      tags: note['tags'].join(' '), content: note['content']
    }
    sql = "INSERT INTO notes VALUES (:key, :deleted, :version, :syncnum,\
           :createdate, :modifydate, :systemtags, :tags, :content)"
    @db.execute(sql, mapping)
  end

  def update_note(note)
    note_db = search_note(note['key'])
    return unless note_db
    note.each do |attr, value|
      # Skip if attr is key or its value is not changed
      next if attr == 'key' || value == note_db[attr]
      value = value.join(' ') if attr == 'tags' || attr == 'systemtags'
      if attr == 'tags' || attr == 'systemtags' || attr == 'content'
        # Quote value if it's TEXT attribute
        sql = "UPDATE notes SET #{attr}=\"#{value}\" WHERE key=?"
      else
        sql = "UPDATE notes SET #{attr}=#{value} WHERE key=?"
      end
      @db.execute(sql, note['key'])
    end
  end

  def mark_note_as_deleted(note)
    note = { 'key' => note['key'], 'deleted' => 1 }
    update_note(note)
  end

  def to_note(entry)
    { 'key' => entry[0], 'deleted' => entry[1],
      'version' => entry[2], 'syncnum' => entry[3],
      'createdate' => entry[4], 'modifydate' => entry[5],
      'systemtags' => entry[6].split(' '),
      'tags' => entry[7].split(' '), 'content' => entry[8] }
  end

  def search_note(key)
    res = @db.execute('SELECT * from notes WHERE key=?', key)
    res.count == 0 ? nil : to_note(res[0])
  end

  def all_notes
    res = @db.execute('SELECT * FROM notes ORDER BY modifydate')
    note_list = []
    res.each do |item|
      note_list.push(to_note(item))
    end
    note_list
  end
end

#-------------------------------------------------------------------------------
