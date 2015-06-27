#!/usr/bin/env ruby
# coding: UTF-8
#-------------------------------------------------------------------------------
# simplenote.rb
#   Author: alpha22jp@gmail.com
#-------------------------------------------------------------------------------

require 'httparty'
require 'http/exceptions'
require 'base64'

#-------------------------------------------------------------------------------
# Simplenote server

class Simplenote
  include HTTParty
  base_uri 'https://simple-note.appspot.com/'

  def initialize(email, password)
    @email = email
    @password = password
    @token = nil
  end

  def token
    @token ||= login
  end

  def params_base
    { auth: token, email: @email }
  end

  def login
    body = HashConversions.to_params(email: @email, password: @password)
    res = Http::Exceptions.wrap_and_check do
      self.class.post('/api/login', body: Base64.encode64(body))
    end
    return res.body
  rescue Http::Exceptions::HttpException => e
    puts 'Login error: ' + e.message
    return nil
  end

  def get_index(mark = nil, note_list = [])
    return nil unless token
    params = params_base.merge(length: 20)
    params.merge!(mark: mark) unless mark.nil?
    res = Http::Exceptions.wrap_and_check do
      self.class.get('/api2/index', query: params, format: :json)
    end
    note_list.concat(res['data'])
    res.key?('mark') ? get_index(res['mark'], note_list) : note_list
  rescue Http::Exceptions::HttpException => e
    puts 'Get index error: ' + e.message
    return nil
  end

  def get_note(key)
    return nil unless token
    res = Http::Exceptions.wrap_and_check do
      self.class.get("/api2/data/#{key}", query: params_base, format: :json)
    end
    return res.parsed_response
  rescue Http::Exceptions::HttpException => e
    puts 'Get note error: ' + e.message
    return nil
  end

  def update_note(note)
    return nil unless token
    res = Http::Exceptions.wrap_and_check do
      self.class.post('/api2/data' + (note.key?('key') ? "/#{note['key']}" : ''),
                      query: params_base, body: note.to_json, format: :json)
    end
    return note.merge(res.parsed_response)
  rescue Http::Exceptions::HttpException => e
    puts 'Update note error: ' + e.message
    return nil
  end

  def create_note(note)
    if note.is_a?(String)
      now = Time.now.to_i
      note = { 'createdate' => now, 'modifydate' => now, 'content' => note }
    end
    update_note(note)
  end

  def delete_note(key)
    return false unless token
    Http::Exceptions.wrap_and_check do
      self.class.delete("/api2/data/#{key}", query: params_base)
    end
    return true
  rescue Http::Exceptions::HttpException => e
    puts 'Delete note error: ' + e.message
    return false
  end
end

#-------------------------------------------------------------------------------
