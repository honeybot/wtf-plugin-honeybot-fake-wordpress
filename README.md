# Fake Wordpress plugin for wtf

This plugin changes application patterns the way, that scanners will recognize Wordpress application in it.
It supports release versions up to 4.9.4.

## Policy example

Mandatory options:
- version: version of Wordpress to emulate
- path: path to data folder (usually installed in /usr/local/share/wtf/data/)

```
{
    "name": "fake-wordpress",
    "version": "0.1",
    "storages": { },
    "plugins": {            
        "honeybot.fake.wordpress": [{
			"version": "7.21",
			"path":"/usr/local/share/wtf/data/honeybot/fake/wordpress/"
		}]
    },
    "actions": {},
    "solvers": {}
}
```