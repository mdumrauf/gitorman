#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'github-manager'
require 'json-dds-helper'

require 'logger'

$logger = Logger.new("gitorman.log")

$logger.info "GitorMan initialized!"

groups = []

def initialize_repo(team_name, repo_name)
  folder_name = team_name.strip.gsub(" ", ".")
  `
    mkdir ./#{folder_name} &&
    cd ./#{folder_name} &&
    echo "# #{team_name}" > ./README .md &&
    git init &&
    git add . &&
    git commit -m 'First commit' &&
    git remote add origin git@github.com:ddsutn/#{repo_name}.git &&
    git push -u origin master &&
    cd ../ &&
    rm -rf #{folder_name}
  `
end

def parse_groups(json_file)
  provider = JsonDDSHelper.new json_file

  groups = provider.confirmed_groups
  groups.each { |group| print "#{group}\n" }

  $logger.info "#{groups.length} groups retrieved from database"

  client = GithubManager.new("dds-utn", "mdumrauf", "xxxxxxxx")

  id_team_owners = "owners"
  number_of_repos = 0

  existing_repos = client.list_repos("private").map { |repo| repo.name }

  $logger.info "#{existing_repos.length} private repos found in Organization: sisoputnfrba"

  new_groups = groups.select { |group|
    !existing_repos.member? "2014-vn-group-#{group}"
  }

  $logger.info "#{new_groups.length} new groups"


  new_groups.each{ |group, users|

    repo_name = "2014-vn-group-#{group}"
    team_name = repo_name

    begin
      $logger.info "Team: #{team_name}\nRepo: #{repo_name}\nUsers: #{users}\n\n"
      client.create_repo(repo_name, "Repositorio de TPs del grupo #{group}")
      client.create_team(team_name, repo_name, users)

      initialize_repo(team_name, repo_name)

      client.add_team_to_repo(id_team_owners, repo_name)
    rescue Exception => e
      $logger.error "Could not create repo or team"
      $logger.error e.message
      $logger.error e.backtrace.inspect
    end

    $logger.info "Created repo: #{repo_name} for team: #{team_name}"
    number_of_repos += 1
  }

  $logger.info "#{number_of_repos} repos and teams were created"


end

begin

  print "\n\nGroups Thursday Morning\n\n"
  parse_groups 'thursday_morn.json'
  print "\n\n-------------------\n\n"
  print "nGroups Friday Night\n\n"
  parse_groups 'friday_night.json'

end
