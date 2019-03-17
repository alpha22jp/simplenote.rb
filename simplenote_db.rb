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
  TEXT = "TEXT"
  INTEGER = "INTEGER"
  def initialize(db_file)
    @db = SQLite3::Database.new(db_file)
    @db.results_as_hash = true
    bool_to_int = ->(i) { i ? 1 : 0 }
    int_to_bool = ->(i) { i == 1 }
    join_with_space = ->(i) { i.join(' ') }
    split_by_space = ->(i) { i.split(' ') }
    no_conv = ->(i) { i }
    @mapping = {
      "key" => [TEXT, no_conv, no_conv],
      "version" => [INTEGER, no_conv, no_conv],
      "deleted" => [INTEGER, bool_to_int, int_to_bool],
      "creationDate" => [TEXT, no_conv, no_conv],
      "modificationDate" => [TEXT, no_conv, no_conv],
      "systemTags" => [TEXT, join_with_space, split_by_space],
      "tags" => [TEXT, join_with_space, split_by_space],
      "shareURL" => [TEXT, no_conv, no_conv],
      "publishURL" => [TEXT, no_conv, no_conv],
      "content" => [TEXT, no_conv, no_conv]
    }
    query = @mapping.collect { |key, attr| "#{key} #{attr[0]}" }.join(", ")
    @db.execute "CREATE TABLE IF NOT EXISTS notes (#{query})"
  end

  def add_note(note)
    keys = @mapping.map { |key, attr| ":#{key}" }.join(", ")
    mapping = @mapping.map { |key, attr| [key, attr[1].call(note[key])] }.to_h
    @db.execute("INSERT INTO notes VALUES (#{keys})", mapping)
  end

  def update_note(note)
    note_db = search_note(note["key"])
    return add_note(note) unless note_db
    note.select { |attr, value|
      # Ignore if attr is key or its value is not changed
      attr != "key" && note_db.key?(attr) && note_db[attr] != value
    }.each do |attr, value|
      value = @mapping[attr][1].call(value)
      if @mapping[attr][0] == TEXT
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
    @mapping.map { |key, attr| [key, attr[2].call(entry[key])] }.to_h
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
