sshkeys puppet module
=====================

The sshkeys puppet module allow the creation and installation of ssh keys.


How it works
============

With the sshkeys module, you define a key that will be generated on the
puppet master. You define where this key should be installed, for the
client key pair, and for the authorized_keys.

When the key has not been generated yet, you may need to run puppet
twice. The key will be generated on the first run, and installed on the
second run.


Usage
=====

In order to tell which node will generate the keys, you need to include
the `sshkeys::keymaster` class on the puppet master node::

  include sshkeys::keymaster

Before installing the key, we need to create it. This is done with the
`create_key` ressource, on the puppet master node. We can create the key
`key1`::

  sshkeys::create_key{key1: }

If we want to install the `key1` key pair for user `user1`, we can use
the `set_client_key_pair` ressource::

  sshkeys::set_client_key_pair{'key1-for-user1':
    keyname => 'key1',
    home => '/home/user1',
    user => 'user1',
  }

The `key1` private and public keys should now be installed for user
`user1` on the node on which we created this ressource.

If we want to allow the key `key1` to connect to the `user2` account,
we use the `set_authorized_keys` ressource::

  sshkeys::set_authorized_keys{'key1-to-user2':
    keyname => 'key1',
    user => 'user2',
    home => '/home/user2',
  }

Now, `user1` should have the `key1` key pair installed on his account,
and be able to login to the `user2` account.


License
=======

This module is released under the GNU General Public License version 3:
http://www.gnu.org/licenses/gpl-3.0.txt


Authors
=======

The sshkeys module is based on the ssh::auth module written by
Andrew E. Schulman <andrex at alumni dot utexas dot net>.

The original ssh::auth module is available at this URL :
http://projects.puppetlabs.com/projects/1/wiki/Module_Ssh_Auth_Patterns

