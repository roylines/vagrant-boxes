class lucid32 {		
	group { "puppet":
	        ensure => "present",
	}
	
	file { "/usr/local/src":
					ensure => directory,
	}
	
	package { "python-software-properties":
	    ensure => latest,
			require => Group['puppet'],
	}

	exec { "update-repositories":
		command => "/usr/bin/apt-get update",
		require => Package['python-software-properties'],
		user => "root",
	}

	exec { "update-gems":
		command => "/opt/ruby/bin/gem update",
		user => "root",
	}
		
	exec { "upgrade-repositories":
					command => "/usr/bin/apt-get upgrade -y",
					timeout => 1200,
          require => Exec['update-repositories'],
          user => "root",
	}  

	package { "git-core":
		ensure => latest,
		require => Exec['upgrade-repositories'],
	}                       
                                
	package { "libssl-dev":
		ensure => latest,
		require => Exec['upgrade-repositories'],
	}

	package { "build-essential":
		ensure => latest,
		require => Exec['upgrade-repositories'],
	}

	exec { "clone-node":
					command => "/usr/bin/git clone -b v0.6 git://github.com/joyent/node.git /usr/local/src/node",
					unless => "/usr/bin/test -d /usr/local/src/node",
					require => [Package['git-core'], File['/usr/local/src']],
	} 

	exec { "checkout-node":
					command => "/usr/bin/git checkout tags/v0.6.12 > /var/tmp/checkout-node",
					cwd => "/usr/local/src/node",
					creates => "/var/tmp/checkout-node",
          require => Exec['clone-node'],
	}                                              

	exec { "configure-node":
         	command => "/usr/local/src/node/configure",
					cwd => "/usr/local/src/node",
					creates => "/usr/local/src/node/out",
          require => [Exec['checkout-node'], Package['libssl-dev'], Package['build-essential']],
          user => "root",
			 } 

	exec { "make-node":
          command => "/usr/bin/make -j2",
					cwd => "/usr/local/src/node",
					creates => "/usr/local/src/node/node",
					timeout => 1200,
					require => Exec['configure-node'],      
          user => "root",
	}       
                
	file { "/usr/local/bin/node":
					ensure => link,
					target => "/usr/local/src/node/node",
					require => Exec['make-node']
	}
                                
	package { "curl":
						ensure => latest,
						require => Exec['upgrade-repositories'],
	}       

	package { "libexpat1-dev":
						ensure => latest,
						require => Exec['upgrade-repositories'],
	}       
	
	exec { "install-npm-initial":
					command => "/usr/bin/curl http://npmjs.org/install.sh | clean=no /bin/sh",
					require => [Package['libexpat1-dev'], Package['curl'], File['/usr/local/bin/node']],
					creates => "/usr/local/bin/npm",
          user => "root",
	}        
                                
	exec { "install-npm":
					command => "/usr/local/bin/npm install npm -g",
					require => Exec['install-npm-initial'],
					creates => "/usr/local/bin/vows",
					user => "root",
	}

	exec { "install-vows":
					command => "/usr/local/bin/npm install vows -g",
					require => Exec['install-npm'],
					creates => "/usr/local/bin/vows",
					user => "root",
	}
}

include lucid32
