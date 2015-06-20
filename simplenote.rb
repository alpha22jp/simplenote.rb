#!/usr/bin/env ruby
# coding: UTF-8
#-------------------------------------------------------------------------------
# simplenote.rb
#   Author: alpha22jp@gmail.com
#-------------------------------------------------------------------------------

require 'time'
require 'base64'
require 'mechanize'
require 'erb'

#-------------------------------------------------------------------------------
# Simplenote server

class Simplenote
  SERVER_URL = 'https://simple-note.appspot.com/'

  def initialize(email, password)
    @email = email
    @password = password
    @token = nil
    @agent = Mechanize.new
    @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @agent.follow_meta_refresh = true
    # @agent.set_proxy('proxy.example.com', 8080)
  end

  def token
    return @token if @token
    url = SERVER_URL + 'api/login'
    form_data = URI.encode_www_form('email' => @email, 'password' => @password)
    begin
      page = @agent.post(url, Base64.strict_encode64(form_data))
    rescue Mechanize::ResponseCodeError => e
      puts "Get token error (#{e.response_code})"
      @token = nil
    else
      @token = page.body
    end
  end

  def get_index(mark = nil, note_list = [])
    return nil unless token
    url = SERVER_URL + 'api2/index'
    params = { 'length' => 100, 'auth' => @token, 'email' => @email }
    params['mark'] = mark unless mark.nil?
    begin
      page = @agent.get(url, params)
    rescue Mechanize::ResponseCodeError => e
      puts "Get index error (#{e.response_code})"
      return nil
    end
    index = JSON.parse(page.body)
    note_list.concat(index['data'])
    if index.key?('mark')
      return get_index(index['mark'], note_list)
    else
      return note_list
    end
  end

  def get_note(key)
    return nil unless token
    url = SERVER_URL + "api2/data/#{key}"
    begin
      page = @agent.get(url, 'auth' => @token, 'email' => @email)
    rescue Mechanize::ResponseCodeError => e
      puts "Get note error (#{e.response_code})"
      return nil
    else
      return JSON.parse(page.body)
    end
  end

  def update_note(note)
    return nil unless token
    api_str = 'api2/data' + (note.key?('key') ? "/#{note['key']}" : '')
    url = SERVER_URL + api_str + "?auth=#{@token}&email=#{@email}"
    begin
      page = @agent.post(url, ERB::Util.url_encode(JSON.generate(note)),
                         'Content-Type' => 'application/json')
    rescue Mechanize::ResponseCodeError => e
      puts "Create note error (#{e.response_code})"
      return nil
    else
      note_new = JSON.parse(page.body)
      note_new['content'] = note['content'] unless note_new['content']
      return note_new
    end
  end

  def create_note(note)
    if note.is_a?(String)
      now = Time.now.to_i
      note = { 'createdate' => now, 'modifydate' => now, 'content' => note }
      return update_note(note)
    else
      update_note(note)
    end
  end

  def delete_note(key)
    return false unless token
    url = SERVER_URL + 'api2/data/' + key
    @agent.delete(url, 'auth' => @token, 'email' => @email)
  end
end

#-------------------------------------------------------------------------------
