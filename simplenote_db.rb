#!/usr/bin/env ruby
# coding: utf-8
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
        (key TEXT, deleted INTEGER, version INTEGER,
         creationDate TEXT, modificationDate TEXT, systemTags TEXT, tags TEXT,
         shareURL TEXT, publishURL TEXT, content TEXT)
        SQL
  end

  def add_note(note)
    p note
    mapping = {
      key: note["key"], deleted: note["deleted"] ? 1 : 0, version: note["version"],
      creationDate: note["creationDate"], modificationDate: note["modificationDate"],
      systemTags: note["systemTags"].join(' '), tags: note["tags"].join(' '),
      shareURL: note["shareURL"], publishURL: note["publishURL"],
      content: note["content"] }
    sql = "INSERT INTO notes VALUES
           (:key, :deleted, :version, :creationDate, :modificationDate,
            :systemTags, :tags, :shareURL, :publishURL, :content)"
    @db.execute(sql, mapping)
  end

  def update_note(note)
    note_db = search_note(note["key"])
    return add_note(note) unless note_db
    note.select { |attr, value|
      # Ignore if attr is key or its value is not changed
      attr != "key" && note_db.key?(attr) && note_db[attr] != value
    }.each do |attr, value|
      value = value.join(' ') if attr == "tags" || attr == "systemTags"
      if attr == "tags" || attr == "systemTags" || attr == "content" ||
         attr == "shareURL" || attr == "publishURL"
        # Quote value if it's TEXT attribute
        sql = "UPDATE notes SET #{attr}=\"#{value}\" WHERE key=?"
      else
        sql = "UPDATE notes SET #{attr}=#{value} WHERE key=?"
      end
      @db.execute(sql, note["key"])
    end
  end

  def mark_note_as_deleted(note)
    note["deleted"] = true
    update_note(note)
  end

  def to_note(entry)
    { "key" => entry[0], "deleted" => entry[1], "version" => entry[2],
      "creationDate" => entry[3], "modificationDate" => entry[4],
      "systemTags" => entry[5].split(' '), "tags" => entry[6].split(' '),
      "shareURL" => entry[7], "publishURL" => entry[8], "content" => entry[9] }
  end

  def search_note(key)
    res = @db.execute('SELECT * from notes WHERE key=?', key)
    res.count == 0 ? nil : to_note(res[0])
  end

  def all_notes
    @db.execute('SELECT * FROM notes ORDER BY modificationDate')
      .map { |i| to_note(i) }
  end
end

#-------------------------------------------------------------------------------
