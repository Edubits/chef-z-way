#
# Cookbook Name:: chef-z-way
# Recipe:: install
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# => Shorten Hashes
zway = node['z-way']
new_install_base = "#{zway['base']}-#{zway['version']}"

# Install dependencies
package ['sharutils', 'tzdata', 'gawk', 'libc-ares2', 'libavahi-compat-libdnssd-dev', 'libarchive-dev', 'libcurl3']

# Check symlinks
link '/usr/lib/arm-linux-gnueabihf/libssl.so' do
	to '/usr/lib/arm-linux-gnueabihf/libssl.so.1.0.0'
end
link '/usr/lib/arm-linux-gnueabihf/libcrypto.so' do
	to '/usr/lib/arm-linux-gnueabihf/libcrypto.so.1.0.0'
end
link '/usr/lib/arm-linux-gnueabihf/libarchive.so.12' do
	to '/usr/lib/arm-linux-gnueabihf/libarchive.so'
end

directory new_install_base

tar_extract "http://razberry.z-wave.me/z-way-server/z-way-server-RaspberryPiXTools-#{zway['version']}.tgz" do
	target_dir new_install_base
	creates "#{new_install_base}/automation"
	tar_flags ['--strip-components=1']
end

if File.exist? zway['base'] and File.realpath("#{zway['base']}") != new_install_base then
	# A Z-Way installation already exists, copy over configuration and data

	if File.exists? "#{zway['base']}/config/Configuration.xml" then
		file "#{new_install_base}/config/Configuration.xml" do
			content File.read "#{zway['base']}/config/Configuration.xml"
			action :create
		end
	end
	if File.exists? "#{zway['base']}/config/Rules.xml" then
		file "#{new_install_base}/config/Rules.xml" do
			content File.read "#{zway['base']}/config/Rules.xml"
			action :create
		end
	end
	if File.exists? "#{zway['base']}/automation/.syscommand" then
		file "#{new_install_base}/automation/.syscommand" do
			content File.read "#{zway['base']}/automation/.syscommand"
			action :create
		end
	end
	ruby_block 'copy directories' do
		block do
			require 'fileutils'
			FileUtils.cp_r "#{zway['base']}/automation/storage",
										 "#{new_install_base}/automation/"
			FileUtils.cp_r "#{zway['base']}/automation/userModules",
										 "#{new_install_base}/automation/"
			FileUtils.cp_r "#{zway['base']}/config/maps",
										 "#{new_install_base}/config/"
			FileUtils.cp_r "#{zway['base']}/config/zddx",
										 "#{new_install_base}/config/"
		end
		only_if { File.exists?("#{zway['base']}/automation/storage") }
	end
end

ruby_block '/boot/cmdline.txt' do
	block do
		file = Chef::Util::FileEdit.new('/boot/cmdline.txt')
		file.search_file_delete(/console=ttyAMA0,115200/)
		file.search_file_delete(/kgdboc=ttyAMA0,115200/)
		file.search_file_delete(/console=serial0,115200/)
		file.write_file
	end
end

# TODO: only on Raspberry Pi 3
ruby_block '/boot/config.txt' do
	block do
		file = Chef::Util::FileEdit.new('/boot/config.txt')
		file.insert_line_if_no_match(/dtoverlay=pi3-miniuart-bt/, 'dtoverlay=pi3-miniuart-bt')
		file.write_file
	end
end

template "#{Chef::Config[:file_cache_path]}/#{zway['version']}.sh" do
	source 'install.sh.erb'
	mode '0755'
	notifies :run, 'execute[install]', :immediately
end

# => Install Z-Way
execute 'install' do
	command "#{Chef::Config[:file_cache_path]}/#{zway['version']}.sh"
	action :nothing
end

service 'z-way-server' do
	service_name 'z-way-server'

	supports restart: true

	action [:enable]
end

link zway['base'] do
	to new_install_base
end

file '/etc/z-way/VERSION' do
	content zway['version']

	# If the version changed, restart
	notifies :restart, 'service[z-way-server]'
end