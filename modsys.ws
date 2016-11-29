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

//let log = function(){}////////////

let Module = require('module')
let path = require('path')
let fs = require('fs')
let vm = require('vm')
let colors = require('colors/safe')

let Mod = fun(name, fn, ctx)
  ret {
    name, fn,
    ctx: ctx || {},
    export_names: [],
    parents: [],
    opts: {},
  }

Mod.prototype = {
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

export let mods = {}
global.M = mods
//global.global_mod = new_module('(global)', global)
global.global_mod = new Mod('(global)', require.main.filename, global)

fun wrap(code, inject)
  code =
    '(function(require,__mod,__dirname){var __ctx=__mod.ctx;with(__ctx){' +
    "'use strict';" +
    code +
    ";__mod.eval=(code)=>eval(code)" +
    //";"+inject +
    '}})'
  //log(code)
  ret code

fun wo_ext(fn)
  ret wo_dir(fn).split('.').shift()

fun wo_dir(fn)
  ret fn.split('/').pop()

fun create_script(mod, name, fn, code)
  try
    ret new vm.Script(code, {filename: wo_dir(fn), displayErrors: true})
  catch (e)
    console.error(colors.red(wo_dir(fn)+': module compilation error'))
    console.error(e)
    if mod.opts.fatal
      process.exit(1)

fun run_script(mod, name, fn, script)
  try
    ret script.runInThisContext()(require.main.require, mod, path.dirname(fn))
  catch (e)
    console.error(colors.red(wo_dir(fn)+': module execution error'))
    console.error(e)
    if mod.opts.fatal
      process.exit(2)

fun bind_export(mod, parent, exp_name)
  let name = mod.name

  //if (!(exp_name in parent_ctx)) {
  //if (!Object.hasOwnProperty(parent_ctx, exp_name)) {
  //if (  Object.keys(parent_ctx).indexOf(exp_name)<0  ) {

  log(colors.green("bind ") + name + '.' + exp_name + ' to ' + parent.name)
  //log(colors.green("bind ") + name + '.' + exp_name + ' to ' + parent.name+' val '+mod.ctx[exp_name])

  try
    Object.defineProperty(parent.ctx, exp_name, {
      enumerable: true,
      configurable: true,
      //configurable: ' assert fs '.indexOf(' '+exp_name+' ')>=0,
      get: function() {
        //console.log(colors.blue('read ')+name+'.'+exp_name+' from '+parent.name)
        let val = mod.ctx[exp_name]
        //console.log(colors.gray(''+val))
        return val
      },
      set: function(val) {
        //console.log(colors.red('write ')+name+'.'+exp_name+colors.gray('='+val)+' from '+parent.name)
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
  log(colors.green('bind as object ')+obj_name+' to '+parent.name)
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
  parent = parent || global_mod
  //log('resolve '+name+' from '+parent.name+' ('+parent.fn+')')
  let fn = name+'.js'
  let r = path.dirname(parent.fn)+'/'+fn
  //log('try '+r)
  if fs.existsSync(r)
    ret r
  let home = process.env.HOME
  r = home+'/mod/'+fn
  //log('try '+r)
  if fs.existsSync(r)
    ret r
  r = home+'/mod/'+name+'/'+fn
  //log('try '+r)
  if fs.existsSync(r)
    ret r
  throw new Error('cant find '+name)

export fun find(fn)
  ret mods[fn]

export fun add(name, fn, code, export_names, ctx, parent, opts)
  parent = parent || global_mod
  if (name == parent.name)
    throw new Error('module '+name+' uses itself')
  if opts.method != 'include'
    opts.method = 'use'
  log(colors.magenta(opts.method)+' '+name+' from '+parent.name)
  let mod = mods[fn]
  if !mod
    //mod = new_module(name)
    mod = mods[fn] = new Mod(name, fn, ctx)
    mod.export_names = export_names
    mod.opts = opts
    /*if opts.inject_ctx
      for name in opts.inject_ctx
        mod.ctx[name] = opts.inject_ctx[name]*/
    //mod.code = ws.code
    code = wrap(code, opts.inject)
    //mod.wrapped_code = code
    //log(code)
    let script = create_script(mod, name, fn, code)
    if script
      run_script(mod, name, fn, script)
    else
      log('script wasnt comipiled')
  else
    log(name+' is cached');
    //log(mod)
  ret mod

export fun bind(mod, parent)
  //log('bind')
  parent = parent || global_mod
  let parents = mod.parents
  if parents.indexOf(parent) < 0
    parents.push( parent )
    if mod.opts.method == 'include'
      //log('bind / include - to '+parent.name)
      bind_exports(mod, parent)
    else
      //log('bind / use - to '+parent.name)
      bind_as_object(mod, parent)

export fun update(fn, code, export_names, parent)
  ret null // do nothing
