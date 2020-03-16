#!/usr/bin/env ruby
# coding: utf-8
#-------------------------------------------------------------------------------
# simplenote.rb
#   Author: alpha22jp@gmail.com
#-------------------------------------------------------------------------------

require 'httparty'
require 'http/exceptions'
require 'base64'
require 'uuid'

class String
  # TODO: need to handle salogate pair
  def unicode_escape
    self.unpack('U*').map{ |i| i < 0x100 ? i.chr : '\u' + i.to_s(16).rjust(4, '0') }.join
  end
end

#-------------------------------------------------------------------------------
# Simplenote server

class Simplenote
  include HTTParty
  APP_ID = "chalk-bump-f49"
  API_KEY = Base64.decode64("YzhjMmI4NjMzNzE1NGNkYWJjOTg5YjIzZTMwYzZiZjQ=")
  URI_API = "https://api.simperium.com/1/" + APP_ID + "/note/"
  URI_AUTH = "https://auth.simperium.com/1/" + APP_ID

  def initialize(email, password)
    @email = email
    @password = password
    @token = nil
  end

  def get_token
    @token ||= authenticate
  end

  def headers_for_api
    { "X-Simperium-Token" => get_token, "Content-Type" => "application/json" }
  end

  def authenticate
    res = Http::Exceptions.wrap_and_check do
      headers = { "X-Simperium-API-Key" => API_KEY }
      body = { "username" => @email, "password" => @password }.to_json
      self.class.base_uri(URI_AUTH)
      self.class.post("/authorize/", headers: headers, body: body, format: :json)
    end
    res["access_token"]
  rescue Http::Exceptions::HttpException => e
    puts "Login error: " + e.message
  end

  def get_index(mark = nil, note_list = [])
    return nil unless get_token
    res = Http::Exceptions.wrap_and_check do
      params = { "data" => true, "limit" => 100 }
      params.merge!("mark" => mark) unless mark.nil?
      self.class.base_uri(URI_API)
      self.class.get("/index", headers: headers_for_api, query: params, format: :json)
    end
    note_list.concat(res["index"])
    res.key?("mark") ? get_index(res["mark"], note_list) : note_list
  rescue Http::Exceptions::HttpException => e
    puts "Get index error: " + e.message
  end

  def get_note(key)
    return nil unless get_token
    res = Http::Exceptions.wrap_and_check do
      self.class.base_uri(URI_API)
      self.class.get("/i/#{key}", headers: headers_for_api, format: :json)
    end
    res.merge!("key" => key, "version" => res.headers["X-Simperium-Version"].to_i)
  rescue Http::Exceptions::HttpException => e
    puts "Get note #{key} error: " + e.message
  end

  def update_note(note)
    return nil unless get_token
    key = note.delete("key")
    version = note.delete("version")
    note["modificationDate"] = Time.now.to_f
    res = Http::Exceptions.wrap_and_check do
      params = { "response" => true }
      self.class.base_uri(URI_API)
      self.class.post("/i/#{key}" + (version ? "/v/#{version.to_s}" : ""),
                      headers: headers_for_api, query: params,
                      body: note.to_json.unicode_escape, format: :json)
    end
    res.merge!("key" => key, "version" => res.headers["X-Simperium-Version"].to_i)
  rescue Http::Exceptions::HttpException => e
    puts 'Update note error: ' + e.message
  end

  def create_note(note_or_string)
    if note_or_string.is_a?(String)
      note = { "creationDate" => Time.now.to_f, "deleted" => false, "content" => note_or_string,
               "tags" => [], "systemTags" => [], "shareURL" => "", "publishURL" => "" }
    end
    note["key"] = UUID.generate(:compact)
    update_note(note)
  end

  def trash_note(note)
    note["deleted"] = true
    update_note(note)
  end

  def delete_note(note)
    return false unless get_token
    # Note has to be trashed before delettion
    note = trash_note(note)
    key = note["key"]
    Http::Exceptions.wrap_and_check do
      self.class.base_uri(URI_API)
      self.class.delete("/i/#{key}", headers: headers_for_api)
    end
    return true
  rescue Http::Exceptions::HttpException => e
    puts 'Delete note error: ' + e.message
  end
end

#-------------------------------------------------------------------------------
