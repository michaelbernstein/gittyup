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
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


#Script to backup all .git files from a given repository to
#a backup repository.   Traverses file trees.


BASE_DIR = "/var/git/"
BACKUP_DIR = "/Users/michael/backup/"


def clone(path)
  puts "Cloning git repo at #{path[:from]} to #{path[:to]}"
  Dir.chdir(path[:to])
  puts `git clone #{path[:from]}`
end

def sync(path)
  puts "Syncing git repo at #{path}"  
  Dir.chdir(path)
  puts `git pull`
end

def traverse_git_directory(path)
  #Make sure we have the trailing slash on all paths.
  path[path.length] = "/" if path[path.length - 1].chr != '/'

  b = Dir[path + "*"]
  
  gits = b.select {|x| x.split('.').last == 'git'}
  (b - gits).each {|non_git| 
      if File.directory?(non_git)
        puts "Entering Directory #{non_git}"
        gits << traverse_git_directory(non_git)
      end
       }
  gits.flatten
end


def create_directory_structure(x)
  git_dir = x.split('/').select {|y| y != ""}
  sub_dir = (git_dir[0..git_dir.size - 2] -  BASE_DIR.split('/').select {|y| y!= ""})

  #If it doesn't, we'll create the path
  unless sub_dir.empty? || File.exists?(BACKUP_DIR + sub_dir.join('/'))
    puts "Doesn't exist - Creating dir: #{BACKUP_DIR + sub_dir.join('/')}"
    Dir.mkdir(BACKUP_DIR + sub_dir.join('/'))
  end
end

def create_action_lists
to_clone = []
to_sync = []

  traverse_git_directory(BASE_DIR).each do |x|
    #step 1, check to see if the entire path exists
    dir = BACKUP_DIR + (x.split('/') - BASE_DIR.split('/')).join('/').split(".git")[0]

    if File.exists?(dir)
      #These are the directories that exist already that are to be cloned!
      to_sync << dir
    else
      create_directory_structure(x)
      temp = dir.split('/')
      to_clone << {:to => temp[0..temp.size - 2].join('/'), :from => x}
    end
  end
  [to_clone, to_sync]
end


list = create_action_lists
list[0].each {|clone_item| clone(clone_item) }
list[1].each {|sync_item| sync(sync_item) }
 