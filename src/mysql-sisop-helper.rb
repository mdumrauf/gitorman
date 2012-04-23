#!/usr/bin/env ruby
require 'rubygems'
require 'mysql'

class MysqlSisopHelper

	def self.confirmed_groups(host, user, pass, db_name)
		begin
		  db = Mysql.real_connect(host, user, pass, db_name)
		  
		  query = "select a.legajo AS legajo, g.nombre AS grupo, a.repo as 'github user'"
		  query += "from ((alumnos a join grupos g) join asignaciones s)"
		  query += "where ((a.idAlumno = s.idAlumno) and (g.idGrupo = s.idGrupo) and (g.confirmado = 2))"
		  query += "order by g.nombre,a.legajo"
		  
		  res = db.query(query)
		  
		  groups = Hash.new{|h,k| h[k] = []}
		  res.each {|row| groups[row[1]] << row[2]}
		ensure
		  # disconnect from server
		  db.close if db

		groups
	end
end