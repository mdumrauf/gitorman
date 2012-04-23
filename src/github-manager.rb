#!/usr/bin/env ruby
require 'rubygems'
require 'github_api'
require 'logger'
require 'mysql'

$logger = Logger.new($stdout)

class GithubManager
  attr_reader :client

  def initialize(organization, login, pass)
    @org = organization
    @client = Github.new(:login => login, :password => pass, :org => @org)
  end
  
  def create_repo(repo_name, description)
    @client.repos.create_repo({
      :org         => @org,
      :name        => repo_name,
      :description => description, 
      :private     => true,
    })
  end

  def initialize_repo(team_name, repo_name)
    `
      cp template-group/ #{team_name}
      cd #{team_name}
      echo "# #{team_name}" > README.md
      echo "" >> README.md
      tree . >> README.md
      git init
      git add .
      git commit -m 'First commit.'
      git remote add origin git@github.com:sisoputnfrba/#{repo_name}.git
      git push -u origin master
      cd ..
      rm -rf #{team_name}
    `
  end

  def delete_repo(repo_name)
    raise "Not yet implemented"
  end

  def create_team(team_name, repo_name, users)
    team = @client.orgs.create_team(@org, {
      :name => team_name,
      :permission => "push",
      :repo_names => ["#{@org}/#{repo_name}"]
    })
    users.each { |user|
      if valid_user?(user)
        @client.orgs.add_member(team.id, user)
      else
        $logger.warn("User: #{user} from Group: #{team_name} is invalid.
         It will not be included in the team.")
      end
    }
  end

  def delete_team(team_name)
    team = @client.orgs.get_team(team_name)
    @client.orgs.delete_team(team.id)
  end

  def valid_user?(user_name)
    begin
      user = @client.users.get_user(user_name)
    rescue
      user = nil
    end
    user != nil
  end

end

#client = GithubManager.new("sisoputnfrba", "mdumrauf", "************")
#client.create_repo("2012-1c-recursantes-vitalicios", "El repo de prueba mas copado de todos")
#client.create_team("2012-1c-recursantes-vitalicios", ["mdumrauf", "jarlakxen", "gastonprieto", "pedropicapiedraasdasd222"])

begin
  db = Mysql.real_connect("some ip", "some user", "some password", "some db")
  
  query = "select a.legajo AS legajo, g.nombre AS grupo, a.repo as 'github user'"
  query += "from ((alumnos a join grupos g) join asignaciones s)"
  query += "where ((a.idAlumno = s.idAlumno) and (g.idGrupo = s.idGrupo) and (g.confirmado = 2))"
  query += "order by g.nombre,a.legajo"
  
  res = db.query(query)
  
  grupos = Hash.new{|h,k| h[k] = []}
  res.each {|row| grupos[row[1]] << row[2]}

  grupos.each{|grupo, alumnos| puts "#{grupo}: #{alumnos.join(", ")}"}

rescue Mysql::Error => e
  $logger.error "Error code: #{e.errno}"
  $logger.error "Error message: #{e.error}"
  $logger.error "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
ensure
  # disconnect from server
  db.close if db
end
