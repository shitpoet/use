let chokidar = require('chokidar')
let ws = require('ws')
//let modsys = ws.run('modsys.ws')
let modsys = ws.load(__dirname+'/modsys.ws')
let patcher = ws.load('../../lab/spur/spur.ws')
patcher.init(modsys)

let default_opts = {}

global.__modsys = modsys // debug
global.__patcher = patcher // debug

fun watch(fn, cb)
  chokidar.watch(fn).on('change', fun(fn) {
    console.log('script changed '+fn)
    cb(fn)
  })
  ret null

fun get(fn)
  let {code, export_names} = ws.read(fn)
  code = patcher.rewrite_module(fn, code)
  code += 'function include(name,opts){global.include(name,__mod,opts)};'
  code += 'function use(name,opts){global.use(name,__mod,opts)};'
  ret {code, export_names}

fun update(fn)
  let {code, export_names} = ws.read(fn)
  patcher.update_module(fn, code)
  //modsys.update(fn, {code,export_names})

fun link(name, parent, opts)
  let fn = modsys.resolve(name, parent)
  let mod = modsys.find(fn)
  if !mod
    let {code, export_names} = get(fn)
    let ctx = patcher.create_context(fn)
    mod = modsys.add(name,fn,code,export_names,ctx,parent,opts)
    watch(fn, fun(fn){
      if opts && opts.restart
        process.exit(8)
      else
        update(fn)
    })
  modsys.bind(mod, parent)

fun link_one(method, a, b, c)
  let name = a, parent = null, opts = {}
  if typeof a == 'string'
    if b && ('name' in b)
      parent = b
      opts = c || {}
    else
      opts = b || {}
    Object.assign(opts, default_opts)
    opts.method = method
    link(name, parent, opts)
  else
    Object.assign(default_opts, a)

fun link_all(method, a, b, c)
  if Array.isArray(a)
    let names = a
    for name of names
      link_one(method, name, b, c)
  else
    link_one(method, a, b, c)

export fun use(names, parent, opts)
  ret link_all('use', names, parent, opts)

export fun include(names, parent, opts)
  ret link_all('include', names, parent, opts)

use.find = fun(name)
  let mods = modsys.mods
  for fn in mods
    let mod = mods[fn]
    if mod.fn == name
      ret mod
    if mod.name == name
      ret mod
