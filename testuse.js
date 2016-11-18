"use strict";

require('cought')
let ws = require('ws')
require('./use.js')

use('m1')

//log(M)
/*
let repl = require("repl")
let r = repl.start({useGlobal: true})
r.on('exit', function() { process.exit() });
*/
let chokidar = require('chokidar')
//for (let fn of ) {
chokidar.watch([__filename, '*.ws', '../spur/spur.ws']).on('change', function(fn) {
  console.log('base script changed '+fn)
  process.exit(8)
})
//}


ws.run('../repl.js')
