'use strict';
var log4js = require('log4js');
var logger = log4js.getLogger('ContnetBackChainWebApp');
var express = require('express');
var bodyParser = require('body-parser');
var http = require('http');
var util = require('util');
var app = express();
var expressJWT = require('express-jwt');
var jwt = require('jsonwebtoken');
var bearerToken = require('express-bearer-token');
var cors = require('cors');
var propReader = require('properties-reader');
var fs = require('fs');

require('./config.js');
var hfc = require('fabric-client');

var helper = require('./app/helper.js');
var invoke = require('./app/invoke-transaction.js');
var query = require('./app/query.js');
var host = process.env.HOST || hfc.getConfigSetting('host');
var port = process.env.PORT || hfc.getConfigSetting('port');
///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// SET CONFIGURATONS ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
app.options('*', cors());
app.use(cors());
//support parsing of application/json type post data
app.use(bodyParser.json());
//support parsing of application/x-www-form-urlencoded post data
app.use(bodyParser.urlencoded({
	extended: false
}));

// set secret variable
app.set('secret', 'secret');
// set channelName variable
app.set('channelName', 'contentbackchainchannel');
// set chainCodeName variable
app.set('chaincodeName', 'ContentBackChain');

app.use(expressJWT({
	secret: 'secret'
}).unless({
	path: ['/users']
}));
app.use(bearerToken());
app.use(function(req, res, next) {
	logger.debug(' ------>>>>>> new request for %s',req.originalUrl);
	if (req.originalUrl.indexOf('/users') >= 0) {
		return next();
	}

	var token = req.token;
	jwt.verify(token, app.get('secret'), function(err, decoded) {
		if (err) {
			res.send({
				success: false,
				message: 'Failed to authenticate token. Make sure to include the ' +
					'token returned from /users call in the authorization header ' +
					' as a Bearer token'
			});
			return;
		} else {
			// add the decoded user name and org name to the request object
			// for the downstream code to use
			req.username = decoded.username;
			req.orgname = decoded.orgName;
			logger.debug(util.format('Decoded from JWT token: username - %s, orgname - %s', decoded.username, decoded.orgName));
			return next();
		}
	});
});

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// START SERVER /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
var server = http.createServer(app).listen(port, function() {
	//Initialize tokens
	var tokenPath = 'artifacts/tokens';
	if (!fs.existsSync(tokenPath)) {
		fs.closeSync(fs.openSync(tokenPath, 'w'));
	}

	var tokens = propReader(tokenPath);
	if(tokens){
		app.set("OrchestratorUserToken", tokens.get('app.token.OrchestratorUser'));
		app.set("ParticipantUserToken", tokens.get('app.token.ParticipantUser'));
	}
});
logger.info('****************** SERVER STARTED ************************');
logger.info('***************  http://%s:%s  ******************',host,port);
server.timeout = 240000;

function getErrorMessage(field) {
	var response = {
		success: false,
		message: field + ' field is missing or Invalid in the request'
	};
	return response;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////// REST ENDPOINTS START HERE ///////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Register and enroll user
app.post('/users', async function(req, res) {
	var username = req.body.username;
	var orgName = req.body.orgName;
	logger.debug('End point : /users');
	logger.debug('User name : ' + username);
	logger.debug('Org name  : ' + orgName);
	if (!username) {
		res.json(getErrorMessage('\'username\''));
		return;
	}
	if (!orgName) {
		res.json(getErrorMessage('\'orgName\''));
		return;
	}

	var existingToken = app.get(username + 'Token')	
	var token =  existingToken ? existingToken : jwt.sign({
		username: username,
		orgName: orgName
	}, app.get('secret'));

	let response = await helper.getRegisteredUser(username, orgName, true);
	logger.debug('-- returned from registering the username %s for organization %s',username,orgName);
	if (response && typeof response !== 'string') {
		logger.debug('Successfully registered the username %s for organization %s',username,orgName);
		response.token = token;
		res.json(response);

		// Persist new token in its file
		if(!existingToken){
			fs.appendFile('artifacts/tokens', 'app.token.' + username + '=' + token + '\n', function (err) {
				if (err) throw err; 
				logger.debug('Token Saved!');
			});
			app.set(username + 'Token', token);
		}
	} else {
		logger.debug('Failed to register the username %s for organization %s with::%s',username,orgName,response);
		res.json({success: false, message: response});
	}

});

// Invoke transaction on chaincode on target peers
app.post('/invoke', async function(req, res) {
	logger.debug('==================== INVOKE ON CHAINCODE ==================');
	var chaincodeName = app.get('chaincodeName');
	var channelName = app.get('channelName');
	var fcn = req.body.fcn;
	var args = req.body.args;
	logger.debug('channelName  : ' + channelName);
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('fcn  : ' + fcn);
	logger.debug('args  : ' + args);
	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!fcn) {
		res.json(getErrorMessage('\'fcn\''));
		return;
	}
	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}
	
	try {
		let message = await invoke.invokeChaincode(channelName, chaincodeName, fcn, [args], req.username, req.orgname);
		res.send(message);
	}catch(error){
	  	res.status(500).json({success: false, message: error.toString()});
	};

});
// Query on chaincode on target peers
app.get('/query', async function(req, res) {
	logger.debug('==================== QUERY BY CHAINCODE ==================');
	var chaincodeName = app.get('chaincodeName');
	var channelName = app.get('channelName');
	let args = req.query.args;
	let fcn = req.query.fcn;
	let peer = req.query.peer;

	logger.debug('channelName : ' + channelName);
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('fcn : ' + fcn);
	logger.debug('args : ' + args);

	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!fcn) {
		res.json(getErrorMessage('\'fcn\''));
		return;
	}
	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	try {
		let message = await query.queryChaincode(channelName, chaincodeName, [args], fcn, req.username, req.orgname);
		res.send(message);
	}catch(error){
	  	res.status(500).json({success: false, message: error.toString()});
	};

});
