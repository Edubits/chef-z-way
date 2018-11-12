#
# Cookbook Name:: chef-z-way
# Recipe:: config
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# => Shorten Hashes
zway = node['z-way']

template '/etc/init.d/z-way-server' do
	source 'startup-z-way-server.sh.erb'
	mode '0755'
end

template '/etc/logrotate.d/z-way-server' do
	source 'log-rotate.erb'
end

directory '/etc/z-way' do
	action :create
end

file '/etc/z-way/box_type' do
	content 'razberry'
end