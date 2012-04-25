#!/usr/bin/env ruby
require 'github-organization-manager'
require 'mysql-sisop-helper'
require 'logger'

$logger = Logger.new("github-manager.log")

$logger.info "GitorMan initialized!"

begin
	groups = MysqlSisopHelper::confirmed_groups("xxx.xxx.x.xxx", "xxxxxx", "xxxxxx", "xxxx")

rescue Mysql::Error => e
  $logger.error "Error code: #{e.errno}"
  $logger.error "Error message: #{e.error}"
  $logger.error "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

$logger.info "#{groups.length} groups retrieved from database"

client = GithubManager.new("sisoputnfrba", "mdumrauf", "*************")

id_team_ayudantes = "xxxxxxx"
number_of_repos = 0

existing_repos = client.list_repos("private").map { |repo| repo.name }

$logger.info "#{existing_repos.length} private repos found in Organization: sisoputnfrba"

new_groups = groups.select { |group|
  !existing_repos.member? "2012-1c-#{group.downcase.strip.gsub(" ", "-")}"
}

new_groups.each{ |group, users|

  repo_name = "2012-1c-#{group.downcase.strip.gsub(" ", "-")}"
  team_name = group

  begin
    client.create_repo(repo_name, "Implementacion del TP Yanero del grupo #{group}")
    client.create_team(team_name, repo_name, users)

    client.initialize_repo(team_name, repo_name)

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
