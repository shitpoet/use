/* dynamic modular system engine

  - modules isolation
  - in-module eval
  - modifiable module-level scope
  - live bindings between modules

*/

/*let _logging = true
let _timing = false

function log(...args) { if (_logging) console.log(...args) }
let l = log
function time(...args) { if (_timing) console.time(...args) }
function timeEnd(...args) { if (_timing) console.timeEnd(...args) }*/

let Module = require('module')
let path = require('path')
let fs = require('fs')
let vm = require('vm')
let colors = require('colors/safe')

let Mod = fun(name, ctx)
  ret {
    name,
    ctx: ctx || {require, __dirname},
    export_names: [],
    parents: [],
    opts: {},
    set_var: fun(name, value)
      this.ctx[name] = value
    ,
    update_var: fun(name, expr)
      this.eval(name+' = '+expr)
    ,
    add_function: fun(name, code)
      this.ctx[name] = this.eval('('+code+')')
    ,
  }

let mods = {}
global.M = mods
//global.global_mod = new_module('(global)', global)
global.global_mod = new Mod('(global)', global)

fun wrap(code, inject)
  code =
    '(function(__mod){with(__ctx=__mod.ctx){' +
    "'use strict';" +
    code +
    ";__mod.eval=(code)=>eval(code)" +
    ";"+inject +
    '}})'
  //log(code)
  ret code

fun wo_ext(fn)
  ret get_file_name(fn).split('.').shift()

fun get_file_name(fn)
  ret fn.split('/').pop()

fun create_script(name, code)
  try
    ret new vm.Script(code, {filename: name, displayErrors: true})
  catch (e)
    console.error(colors.red(wo_ext(fn)+': module compilation error'))
    console.error(e)

fun run_script(name, script, mod)
  try
    ret script.runInThisContext()(mod)
  catch (e)
    console.error(colors.red(wo_ext(name)+': module execution error'))
    console.error(e)

/*fun new_module(name, ctx)
  ret {
    name,
    ctx: ctx || {require, __dirname},
    export_names: [],
    parents: [],
    opts: {}
  }*/

fun bind_export(mod, parent, exp_name)
  let name = mod.name

  //if (!(exp_name in parent_ctx)) {
  //if (!Object.hasOwnProperty(parent_ctx, exp_name)) {
  //if (  Object.keys(parent_ctx).indexOf(exp_name)<0  ) {

  //log(colors.green("bind ") + name + '.' + exp_name + ' to ' + parent.name)
  //log(colors.green("bind ") + name + '.' + exp_name + ' to ' + parent_name+' val '+$__modules[name].context[exp_name])

  try
    Object.defineProperty(parent.ctx, exp_name, {
      enumerable: true,
      configurable: true,
      //configurable: ' assert fs '.indexOf(' '+exp_name+' ')>=0,
      get: function() {
        //log(colors.blue('read ')+name+'.'+exp_name+' from '+parent.name)
        let val = mod.ctx[exp_name]
        //log(colors.gray(''+val))
        return val
      },
      set: function(val) {
        //log(colors.red('write ')+name+'.'+exp_name+colors.gray('='+val)+' from '+parent.name)
        mod.ctx[exp_name] = val
      },
    })
  catch (e)
    console.error('cant bind exported object')
    console.error(e)
    console.error( Object.getOwnPropertyDescriptor(global, 'log') )

fun bind_exports(mod, parent)
  //let parent_name = parent.name || '(global)'
  for exp_name of mod.export_names
    bind_export(mod, parent, exp_name)

fun bind_as_object(mod, parent)
  let obj_name = wo_ext(mod.name)
  log('bind as object '+obj_name+' to '+parent.name)
  /*let mod_obj = new Proxy({}, {
    get: function(obj, prop) {
      //log(colors.blue('read ')+name+'.'+exp_name+' from '+parent.name)
      ret mod.ctx[prop]
      //log(colors.gray(''+val))
    },
    set: function(obj, prop, val) {
      mod.ctx[prop] = val
    }
  })*/
  Object.defineProperty(parent.ctx, obj_name, {
    enumerable: true,
    configurable: true,
    get: fun() {
      ret mod.ctx
    },
  })

export fun resolve(name, parent)
  let fn = name+'.js'
  if fs.existsSync(fn)
    ret fn
  let home = process.env.HOME
  let modfn = home+'/mod/'+fn
  if fs.existsSync(modfn)
    ret modfn
  modfn = home+'/mod/'+name+'/'+fn
  if fs.existsSync(modfn)
    ret modfn
  throw new Error('cant find '+name)

export fun find(name)
  ret mods[name]

export fun add(name, ws, parent, opts)
  parent = parent || global_mod
  if (name == parent.name)
    throw new Error('module '+name+' uses itself')
  log('use '+name+' from '+parent.name)
  let mod = mods[name]
  if !mod
    //mod = new_module(name)
    mod = mods[name] = new Mod(name, opts.ctx)
    mod.export_names = ws.export_names
    mod.opts = opts
    if opts.inject_ctx
      for name in opts.inject_ctx
        mod.ctx[name] = opts.inject_ctx[name]
    let code = wrap(ws.code, opts.inject)
    let script = create_script(name, code)
    if (script) run_script(name, script, mod)
  else
    log(name+' is cached');

  // bind
  log('bind')
  let parents = mod.parents
  if parents.indexOf(parent) < 0
    parents.push( parent )
  for parent of parents
    if opts.method == 'include'
      log('bind - include')
      bind_exports(mod, parent)
    else
      log('bind - use')
      bind_as_object(mod, parent)

  ret mod

//todo: refactor following funcs to mod.methods ?

export fun update(fn, ws, parent)
  ret null // do nothing

/*export fun mod_eval(fn, code)
  ret mods[fn].eval(code)

/*export fun set_mod_var(fn, name, value)
  mods[fn].__ctx[name] = value

/*export fun update_var(fn, name, expr)
  mod_eval(fn, name+' = '+expr)*/
