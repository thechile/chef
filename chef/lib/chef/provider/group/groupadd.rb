#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Provider
    class Group
      class Groupadd < Chef::Provider::Group

        # Create the group
        def create_group
          command = "groupadd"
          command << set_options
          run_command(:command => command)    
        end
        
        # Manage the group when it already exists
        def manage_group
          command = "groupmod"
          command << set_options
          run_command(:command => command)
        end
        
        # Remove the group
        def remove_group
          run_command(:command => "groupdel #{@new_resource.group_name}")
        end
        
        # Little bit of magic as per Adam's useradd provider to pull the assign the command line flags
        #
        # ==== Returns
        # <string>:: A string containing the option and then the quoted value
        def set_options
          opts = ""
          { :gid => "-g" }.sort { |a,b| a[0] <=> b[0] }.each do |field, option|
            if @current_resource.send(field) != @new_resource.send(field)
              if @new_resource.send(field)
                Chef::Log.debug("#{@new_resource}: setting #{field.to_s} to #{@new_resource.send(field)}")
                opts << " #{option} '#{@new_resource.send(field)}'"
              end
            end
          end
          opts << " #{@new_resource.group_name}"
        end
        
      end
    end
  end
end