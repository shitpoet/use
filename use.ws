// combines modules:
// `ws` - read and curlify sources
// `slowmod` - dynamic modular system
// `spur` - hot patcher

let chokidar = require('chokidar')
let ws = require('ws')
//let modsys = ws.run('modsys.ws')
let modsys = ws.load('modsys.ws')
let patcher = ws.load('../spur/spur.ws')
patcher.init(modsys)

global.__modsys = modsys // debug
global.__patcher = patcher // debug

fun watch(fn, cb)
  chokidar.watch(fn).on('change', fun(fn) {
    console.log('script changed '+fn)
    cb(fn)
  })
  ret null

fun link(names, parent_mod, opts)
  //parent_mod = parent_mod || global_mod
  //if (typeof opts == 'undefined') opts = {}
  //opts = opts = {}
  for name of names.split(' ')
    let fn = modsys.resolve(name, parent_mod)
    if !(modsys.find(fn))
      let {code, export_names} = ws.read(fn)
      code = patcher.rewrite_module(fn, code)
      let mod = modsys.add(fn, {code,export_names}, parent_mod, {
        inject_ctx: patcher.create_inject_context(fn),
        inject: 'function use(name){global.use(name,__mod)}',
        method: opts.method
      })
      /*modsys.add(fn, ws.read(fn), parent_mod, {
        inject: 'function use(name){global.use(name,__mod)}'
      })*/
      watch(fn, fun(fn){
        if opts && opts.restart
          process.exit(8)
        else
          let {code, export_names} = ws.read(fn)
          patcher.update_module(fn, code)
          modsys.update(fn, {code,export_names})
      })

export fun use(names, parent, opts)
  if parent && !('name' in parent)
    opts = parent
    parent = null
  opts = opts || {}
  opts.method = 'use'
  ret link(names, parent, opts)

export fun include(names, parent, opts)
  if parent && !('name' in parent)
    opts = parent
    parent = null
  opts = opts || {}
  opts.method = 'include'
  ret link(names, parent, opts)
