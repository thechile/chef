#
# Author:: Steven Danna (<steve@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'spec_helper'

Chef::Knife::UserCreate.load_deps

describe Chef::Knife::UserCreate do
  let(:knife) { Chef::Knife::UserCreate.new }

  before(:each) do
    @stdout = StringIO.new
    @stderr = StringIO.new
    allow(knife.ui).to receive(:stdout).and_return(@stdout)
    allow(knife.ui).to receive(:stderr).and_return(@stderr)
  end

  shared_examples_for "mandatory field missing" do
    context "when field is nil" do
      before do
        knife.name_args = name_args
      end

      it "exits 1" do
        expect { knife.run }.to raise_error(SystemExit)
      end

      it "prints the usage" do
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end

      it "prints a relevant error message" do
        expect { knife.run }.to raise_error(SystemExit)
        expect(@stderr.string).to match /You must specify a #{fieldname}/
      end
    end
  end

  context "when USERNAME isn't specified" do
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { [] }
      let(:fieldname) { 'username' }
    end
  end

  context "when DISPLAY_NAME isn't specified" do
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { ['some_user'] }
      let(:fieldname) { 'display name' }
    end
  end

  context "when FIRST_NAME isn't specified" do
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { ['some_user', 'some_display_name'] }
      let(:fieldname) { 'first name' }
    end
  end

  context "when LAST_NAME isn't specified" do
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { ['some_user', 'some_display_name', 'some_first_name'] }
      let(:fieldname) { 'last name' }
    end
  end

  context "when EMAIL isn't specified" do
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { ['some_user', 'some_display_name', 'some_first_name', 'some_last_name'] }
      let(:fieldname) { 'email' }
    end
  end

  context "when PASSWORD isn't specified" do
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { ['some_user', 'some_display_name', 'some_first_name', 'some_last_name', 'some_email'] }
      let(:fieldname) { 'password' }
    end
  end

  context "when all mandatory fields are validly specified" do
    before do
      knife.name_args = ['some_user', 'some_display_name', 'some_first_name', 'some_last_name', 'some_email', 'some_password']
      allow(knife).to receive(:edit_data).and_return(knife.user.to_hash)
      allow(knife).to receive(:create_user_from_hash).and_return(knife.user)
    end

    before(:each) do
      # reset the user field every run
      knife.user_field = nil
    end

    it "sets all the mandatory fields" do
      knife.run
      expect(knife.user.username).to eq('some_user')
      expect(knife.user.display_name).to eq('some_display_name')
      expect(knife.user.first_name).to eq('some_first_name')
      expect(knife.user.last_name).to eq('some_last_name')
      expect(knife.user.email).to eq('some_email')
      expect(knife.user.password).to eq('some_password')
    end

    context "when user_key and no_key are passed" do
      before do
        knife.config[:user_key] = "some_key"
        knife.config[:no_key] = true
      end
      it "prints the usage" do
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end

      it "prints a relevant error message" do
        expect { knife.run }.to raise_error(SystemExit)
        expect(@stderr.string).to match /You cannot pass --user-key and --no-key/
      end
    end

    context "when user_key and no_key are passed" do
      before do
        knife.config[:user_key] = "some_key"
        knife.config[:no_key] = true
      end
      it "prints the usage" do
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end

      it "prints a relevant error message" do
        expect { knife.run }.to raise_error(SystemExit)
        expect(@stderr.string).to match /You cannot pass --user-key and --no-key/
      end
    end

    context "when --admin is passed" do
      before do
        knife.config[:admin] = true
      end

      it "sets the admin field on the user to true" do
        knife.run
        expect(knife.user.admin).to be_truthy
      end
    end

    context "when --admin is not passed" do
      it "does not set the admin field to true" do
        knife.run
        expect(knife.user.admin).to be_falsey
      end
    end

    context "when --no-key is passed" do
      before do
        knife.config[:no_key] = true
      end

      it "does not set user.create_key" do
        knife.run
        expect(knife.user.create_key).to be_falsey
      end
    end

    context "when --no-key is not passed" do
      it "sets user.create_key to true" do
        knife.run
        expect(knife.user.create_key).to be_truthy
      end
    end

    context "when --user-key is passed" do
      before do
        knife.config[:user_key] = 'some_key'
        allow(File).to receive(:read).and_return('some_key')
        allow(File).to receive(:expand_path)
      end

      it "sets user.public_key" do
        knife.run
        expect(knife.user.public_key).to eq('some_key')
      end
    end

    context "when --user-key is not passed" do
      it "does not set user.public_key" do
        knife.run
        expect(knife.user.public_key).to be_nil
      end
    end

    context "when a private_key is returned" do
      before do
        allow(knife).to receive(:create_user_from_hash).and_return(Chef::User.from_hash(knife.user.to_hash.merge({"private_key" => "some_private_key"})))
      end

      context "when --file is passed" do
        before do
          knife.config[:file] = '/some/path'
        end

        it "creates a new file of the path passed" do
          filehandle = double('filehandle')
          expect(filehandle).to receive(:print).with('some_private_key')
          expect(File).to receive(:open).with('/some/path', 'w').and_yield(filehandle)
          knife.run
        end
      end

      context "when --file is not passed" do
        it "prints the private key to stdout" do
          expect(knife.ui).to receive(:msg).with('some_private_key')
          knife.run
        end
      end
    end

  end # when all mandatory fields are validly specified
end
