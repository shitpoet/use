module.exports = require('ws').load(__dirname+'/use.ws')
global.use = module.exports.use
global.include = module.exports.include





