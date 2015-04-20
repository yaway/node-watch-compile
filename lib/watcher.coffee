EventEmitter = (require "events").EventEmitter
chokidar = require('chokidar')
class Watcher extends EventEmitter
    constructor:(@watchRoot)->
        @init()
    init:()->

        @watcher = chokidar.watch @watchRoot,{
          persistent: true
          usePolling: true
          interval: 100
          ignoreInitial: true
        }
        @watcher.on "add",(path)=>
            @emit "change",path
        @watcher.on "change",(path)=>
            @emit "change",path

module.exports = Watcher
