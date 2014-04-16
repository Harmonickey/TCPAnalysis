TCPAnalysis
===========

Problems in Cloud Computing - Project 8 - Northwestern University - TCP Analysis Tool

How To Install
==============

Go into the master directory and execute the following.  You may need to skip to How to Add and Build first to get this gem file.

$> gem install tcpanalysis-0.0.0.gem

How to Add and Build
====================

When you add files to bin or lib make sure you add them into the gemspec accordingly.
The gemspec is located in the master directory called tcpanalysis.gemspec

In order to build the gem, for others to install later, execute the following.

$> gem build tcpanalysis.gemspec

If there is an error, you may need to check your gemspec file or you may need to execute in sudo.

How to Push to Github
=====================

When you have made your changes and ready to push back to github, you can simply do the following.

$> git commit -am "My commit message"
$> git push -u origin master

-u will add your user name to the commit's push on github.  Make sure you have your git config totally created.  If not, execute the following.

$> git config --global user.name "Alex Ayerdi"
$> git config --global user.email AAyerdi@u.northwestern.edu

*Note that there are no quotation marks for the email.*

This all ensures for proper version control and documentation.  Branches are suggested for testing, but not necessary.

How to Install libpcap and libpcap-ruby
=======================================

You are going to need two library files in order to use the pcaprub rubygem that is included in the TCPAnlysis tool.

Ubuntu/Linux - You may need to be sudo to run this command.
$> aptitude install libpcap-dev libpcap-ruby
or
$> apt-get install libpcap-dev libpcap-ruby

Other UNIX flavors -
$> Some command that installs libpcap-dev and libpcap-ruby
