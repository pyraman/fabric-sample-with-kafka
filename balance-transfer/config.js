var util = require('util');
var path = require('path');
var hfc = require('fabric-client');

var file = 'network-config%s.yaml';

var env = process.env.TARGET_NETWORK;
if (env)
	file = util.format(file, '-' + env);
else
	file = util.format(file, '');
// indicate to the application where the setup file is located so it able
// to have the hfc load it to initalize the fabric client instance
hfc.setConfigSetting('network-connection-profile-path',path.join(__dirname, 'artifacts' ,file));
hfc.setConfigSetting('ExporterOrg-connection-profile-path',path.join(__dirname, 'artifacts', 'exporterorg.yaml'));
hfc.setConfigSetting('exporterbankorg-connection-profile-path',path.join(__dirname, 'artifacts', 'exporterbankorg.yaml'));

hfc.setConfigSetting('ImporterOrg-connection-profile-path',path.join(__dirname, 'artifacts', 'importerorg.yaml'));
hfc.setConfigSetting('importerbankorg-connection-profile-path',path.join(__dirname, 'artifacts', 'importerbankorg.yaml'));

hfc.setConfigSetting('exportingentityorg-connection-profile-path',path.join(__dirname, 'artifacts', 'exportingentityorg.yaml'));
hfc.setConfigSetting('carrierorg-connection-profile-path',path.join(__dirname, 'artifacts', 'carrierorg.yaml'));
hfc.setConfigSetting('regulatororg-connection-profile-path',path.join(__dirname, 'artifacts', 'regulatororg.yaml'));

// some other settings the application might need to know
hfc.addConfigFile(path.join(__dirname, 'config.json'));
