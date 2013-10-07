#!/bin/bash -ex
[[ $RUBY ]] || (echo 'please set $RUBY' && exit 1)
source ~/.bashrc

#######################################################
# update rvm
rvm get stable
rvm reload

#######################################################
# get rid of binary meta data
echo -n > $rvm_path/user/md5
echo -n > $rvm_path/user/sha512
echo -n > $rvm_path/user/db || true

#######################################################
# build the binary
rvm alias delete $RUBY
rvm remove $RUBY
rvm install $RUBY --verify-downloads 1
rvm prepare $RUBY

#######################################################
# make sure bundler works
rvm $RUBY do gem install bundler
rvm $RUBY do bundle install

#######################################################
# publish to bucket
gem install travis-artifacts
travis-artifacts upload --path $RUBY.* --target-path binary

#######################################################
# make sure it installs
rvm remove $RUBY
echo "rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies
rvm_remote_server_path3=binary
rvm_remote_server_verify_downloads3=1" > $rvm_path/user/db
rvm use $RUBY --install --binary --fuzzy