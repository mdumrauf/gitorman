require 'rubygems'
require 'json'

class JsonDDSHelper

  def initialize(json_file)
    json = File.read(json_file)
    @students = JSON.parse(json)
  end

  def confirmed_groups
    begin
      groups = Hash.new{|h,k| h[k] = []}
      @students.each {|row| groups[row['Grupo']] << row['User'] }
    end
    groups
  end

end
