# The MIT License
# 
# Copyright (c) 2009 Michael Bernstein <michael #_at_# spaceshipknows.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA
# BILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


#Script to backup all .git files from a given repository to
#a backup repository.   Traverses file trees.

require 'fileutils'

BASE_DIR = "/var/git/"
BACKUP_DIR = "/Users/michael/backup/"


def clone(origin, destination)
  puts "Cloning git repo at #{origin} to #{destination}"
  puts `git clone #{origin} #{destination}` 
end

def sync(path)
  Dir.chdir(path)  
  puts "Syncing #{path} --- " + `git pull` + "\n"
end


def convert_to_backup_path(original_path, new_path, base_path)
  new_path +  (original_path.split('/') - base_path.split('/')).join('/') + '/'
end

def pull_off_git_repo(path)
  split = path.split('/')
  split[0..split.size - 2].join('/')
end

def clone_or_sync(repo_name, origin, destination)
  #Check to see if the destination + repo_name exist
  if File.exist?(destination + '/' + repo_name)
    sync(destination + '/' + repo_name)
  else
    clone(origin, destination + '/' + repo_name)
  end
end

def traverse_git_directory(path)
  #Make sure we have the trailing slash on all paths.
  path << '/' if path[path.length - 1].chr != '/'

  #Grab all the directories in the given path
  b = Dir[path + "*"]
  
  #Get all the directories with git in them
  gits = b.select {|x| x.split('.').last == 'git'}
  
  gits.each do |x|
    path = pull_off_git_repo(convert_to_backup_path(x, BACKUP_DIR, BASE_DIR))
    FileUtils.mkdir_p(path) unless File.exist?(path)
    clone_or_sync(x.split('/').last, x, path)
  end

  #Create the next level of paths
  (b - gits).each {|non_git| 
      traverse_git_directory(non_git) if File.directory?(non_git) 
  }
end

traverse_git_directory(BASE_DIR)