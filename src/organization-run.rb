#!/usr/bin/env ruby
require 'github-organization-manager'
require 'mysql-sisop-helper'
require 'logger'

$logger = Logger.new("github-manager.log")

begin
	groups = MysqlSisopHelper::confirmed_groups("xxx.xxx.x.xxx", "xxxxxx", "xxxxxx", "xxxx")

rescue Mysql::Error => e
  $logger.error "Error code: #{e.errno}"
  $logger.error "Error message: #{e.error}"
  $logger.error "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

client = GithubManager.new("sisoputnfrba", "mdumrauf", "*************")

id_team_ayudantes = "xxxxxxx"
number_of_repos = 0

groups.each{ |group, users|

  repo_name = "2012-1c-#{group.downcase.strip.gsub(" ", "-")}"
  team_name = group

  begin
    client.create_repo(repo_name, "Implementacion del TP Yanero del grupo #{group}")
    client.create_team(team_name, repo_name, users)

    client.initialize_repo(team_name, repo_name)

    client.add_team_to_repo(id_team_ayudantes, repo_name)
  rescue
    $logger.error "Could not create repo or team #{repo_name}"
  end
  $logger.info "Created repo: #{repo_name} for team: #{team_name}"
  number_of_repos++
}

$logger.info "#{number_of_repos}/#{groups.length} repos and teams created"
