#
# Cookbook Name:: chef-z-way
# Recipe:: mongoose
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

tar_extract 'http://razberry.z-wave.me/mongoose.pkg.rPi.tgz' do
	target_dir '/'
	creates '/usr/sbin/mongoose'
end

tar_extract 'http://razberry.z-wave.me/webif_raspberry.tar.gz' do
	target_dir '/'
	creates '/var/webif'
end

service 'mongoose' do
	service_name 'mongoose'

	supports restart: true, status: true, reload: true

	action [:enable, :start]
end