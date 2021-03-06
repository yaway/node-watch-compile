fs = require("fs");
vm = require("vm");
globalConfig = require "./globalConfig"
Watcher = require "./watcher"
pathModule = require "path"
child_process = require "child_process"
wrench = require "wrench"
Queue = require "./queue"
DateString = require "./dateString"
Rule = require "./rule"
ChangeMap = require "./changeMap"
commander = require("commander");
program = commander
    .option("-f,--file <filename>","specifail the watchfile default is Watchfile")
    .option("-c,--create-default","create and default rules save as ./Watchfile")
    .option("-v,--version","print version")
    .option("-s,--start-compile","compile all matched file at start")
    .option("-q,--quit","combined with -s, quit program after start compile")
    .option("--no-hash-check","don't check file content hash change")
    .option("--verbose","be verbose")
    .option("--shell <shell-path>","exec shell path")
    .version("0.0.5")
    .parse(process.argv);

defaultWatchFile = """//{basename} /css/style.less => style.less
//{fullpath} /css/style.less => /css/style.less (unchanged)
//{filename} /css/style.less => style
//{extname}  /css/style.less => .less
//{directory} /css/style.less => /css/
exports.watchList = [
    // [testFunctionOrRegExp,commandToRun]
    // [RegExp|(path:string)=>boolean,string]
    [/^.*\.coffee$/,'coffee -c {fullpath}'],
    [/^.*\.less$/,'lessc {fullpath} > {directory}{filename}.css'],
];

exports.serviceList = [
    //commandToRunOnceAtStart
    "echo watchcompile start",
]
"""
if program.createDefault
    console.log "create default Watchfile at ./Watchfile"
    if fs.existsSync "./Watchfile"
        console.error "./Watchfile exists, don't overwrite it."
        process.exit(1);
    fs.writeFileSync "./Watchfile",defaultWatchFile
    console.log "done create default watchfile"

# avoid Warnning->possible EventEmitter memory leak detected. 11 listeners added. Use emitter.setMaxListeners() to increase limit.
process.stdout.setMaxListeners(2000)
process.stderr.setMaxListeners(2000)
ignoreHidden = !program.all;
watchFile = program.file || "./Watchfile";
noHashCheck = program.noHashCheck || false
watchFolders = ["./"]
try
    context = vm.createContext({exports:{},console})
    WatchfileCode = fs.readFileSync(watchFile)
    vm.runInContext(WatchfileCode,context,"watchFile")
    list = context.exports.watchList || []
    serviceList = context.exports.serviceList || []
    watchFolders = context.exports.watches || ["./"]
catch e
    console.error "invalid watchfile '%s'",watchFile
    process.exit(1)

for service in serviceList
    do (service)->
        cp = child_process.exec(service)
        cp.stdout.pipe(process.stdout)
        cp.stderr.pipe(process.stderr)

if program.shell
    globalConfig.shell = program.shell
    console.log "Using shell",globalConfig.shell
rules = []
queue = new Queue(program.verbose)
changeMap = new ChangeMap()
for config in list
    rules.push new Rule config

## Calculate watch dir
if typeof watchFolders is "string"
    watchFolders = [watchFolders]
if !watchFolders.forEach
    throw new Error("Invalid watchfolder")
watchFileFolder = pathModule.dirname(watchFile)
#watchFolders = watchFolders.map folder => pathModule.join(watchFileFolder,folder)

console.log watchFolders
if program.startCompile
    for folder in watchFolders
        files = wrench.readdirSyncRecursive pathModule.join watchFileFolder,folder
        for path in files
            path = pathModule.join(folder,path)
            for rule in rules
                if rule.test path
                    task = rule.taskFromPath path
                    console.log "#{DateString.genReadableDateString()} create #{task.toString()} by #{path}: inital compile"
                    queue.add task
watcher = new Watcher(watchFolders)

watcher.on "change",(path)->
    if not noHashCheck && not changeMap.checkAndUpdate(path)
        if program.verbose
            console.log("#{path} file changed but content hash doesn't, skip it.")
        return
    for rule in rules
        if rule.test path
            task = rule.taskFromPath path
            console.log "#{DateString.genReadableDateString()} create #{task.toString()} by #{path}: modification"
            queue.add task

queue.on "empty",()->
    if program.startCompile and program.quit
        console.log "start compile done and quit by -q"
        process.exit(0)
if not program.quit
    console.log "start watching"
