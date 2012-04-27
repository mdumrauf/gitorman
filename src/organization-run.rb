#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'github-manager'
require 'mysql-sisop-helper'
require 'logger'

$logger = Logger.new("github-manager.log")

$logger.info "GitorMan initialized!"

groups = []

def initialize_repo(team_name, repo_name)
  folder_name = team_name.strip.gsub(" ", ".")
  `
    cp -R template-group/ ./#{folder_name} &&
    cd ./#{folder_name} &&
    echo "# #{team_name}" > ./README-aux.md &&
    echo "" >> ./README-aux.md &&
    cat README.md >> ./README-aux.md &&
    cat README-aux.md > README.md &&
    rm README-aux.md &&
    git init &&
    git add . &&
    git commit -m 'First commit' &&
    git remote add origin git@github.com:sisoputnfrba/#{repo_name}.git &&
    git push -u origin master &&
    cd ../ &&
    rm -rf #{folder_name}
  `
end


sql_instance = MysqlSisopHelper.new("190.228.29.57", "catedrasos", "3243F6A8885A308D31319", "inscr")

begin
	groups = sql_instance.confirmed_groups

rescue Mysql::Error => e
  $logger.error "Error code: #{e.errno}"
  $logger.error "Error message: #{e.error}"
  $logger.error "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

$logger.info "#{groups.length} groups retrieved from database"

client = GithubManager.new("sisoputnfrba", "mdumrauf", "matiiar50zx0o")

id_team_ayudantes = "169375"
number_of_repos = 0

existing_repos = client.list_repos("private").map { |repo| repo.name }

$logger.info "#{existing_repos.length} private repos found in Organization: sisoputnfrba"

new_groups = groups.select { |group|
  !existing_repos.member? "2012-1c-#{group.downcase.strip.gsub(" ", "-")}"
}

begin
new_groups.each{ |group, users|

  repo_name = "2012-1c-#{group.downcase.strip.gsub(" ", "-")}"
  team_name = group

  begin
    client.create_repo(repo_name, "Implementacion del TP Yanero del grupo #{group}")
    invalid_users = client.create_team(team_name, repo_name, users)

    initialize_repo(team_name, repo_name)

    client.add_team_to_repo(id_team_ayudantes, repo_name)
  rescue Exception => e
    $logger.error "Could not create repo or team"
    $logger.error e.message
    $logger.error e.backtrace.inspect
  end

  $logger.info "Created repo: #{repo_name} for team: #{team_name}"
  number_of_repos += 1
}

$logger.info "#{number_of_repos} repos and teams were created"

# Send an email to each invalid github users

mail = Mail.new do
  :from    "sisop.utnfrba@gmail.com"
  :subject "Usuario de Github inválido"
  :body     File.read("invalid-github-user-mail.txt")
end

smtp = Net::SMTP.start("smtp.gmail.com", 465)
      Mail.defaults { delivery_method :smtp_connection, {:connection => smtp} }

emails = sql_instance.get_emails(invalid_users)

emails.each_char { |email|
  mail[:to] = email
  mail.deliver!
}