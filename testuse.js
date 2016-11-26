"use strict";

let colors = require('colors/safe')

let chokidar = require('chokidar')
//for (let fn of ) {
chokidar.watch([__filename, '*.ws', 'm2.js', '../spur/spur.ws']).on('change', function(fn) {
  console.log('base script changed '+fn)
  process.exit(8)
})
//}

require('cought')
let ws = require('ws')
require('./use.js')
include('log')

global.E = {}
for (let name in global.M) {
  let short_name = name.split('/').pop().split('.').shift()
  E[ short_name ] = function(code) { return M[name].eval(code) }
}

let reverse = false
let fn1 = 'm1'
let fn2 = 'm2'
let expect_1 = 1, expect_2 = 2
if (reverse) {
  [fn1,fn2] = [fn2,fn1];
  [expect_1, expect_2] = [expect_2, expect_1];
}

use('m1', {restart: true})
//include('m1', {restart: true})

//foo()
//let result_1 = test_var

/*__patcher.update_module(fn1, ws.read(fn2+'.js').code)
foo()
let result_2 = test_var

if (result_2 == expect_2 && result_1 == expect_1)
  console.log(colors.green('ok'))
else
  console.log(colors.red('NOT UPDATED!'))*/

//ws.run('../repl.js')
use('repl')

