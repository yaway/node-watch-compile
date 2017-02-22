node-watch-compile
==================
# Note
Only tested under linux.Nodejs's fs.watch is used to watch file changes,but these API is not gareteed in all platform.The availability can be found at http://nodejs.org/api/fs.html#fs_availability

An watch-compile tool for nodejs.Useful for webdev real-time compilation for less/coffee or what ever.
# Install
```bash
sudo npm install -g watch-compile
```

# Usage
```bash
# watchcompile or nwc
# create a template Watchfile
watchcompile -c
# Run it
watchcompile -s
# Or run with parameters
# watchcompile -f Watchfile -i 300
```

`-f` is used to specify the Watchfile which contained watch rules. default is "./Watchfile"
`-i` special the minimum recompile interval. Default to 500ms.
`-s` make watchcompile run initial compilation for all matched files.

When changes occured between minimum interval, the compile process will not be aborted, and the latest change will get compiled. In order to prevent unwanted result the -i should be less than default settings.

When change happend after minimum compile interval, an recompile will be triggered immediately. In case the previous compilation of the same file and same command is still running, that previous compilation task will be stopped immediately.

#Watchfile
```bash
#create an default Watchfile at ./
watchcompile -c
```
A default Watchfile is like below
```javascript
//{basename} /css/style.less => style.less
//{fullpath} /css/style.less => /css/style.less (unchanged)
//{filename} /css/style.less => style
//{extname}  /css/style.less => .less
//{directory} /css/style.less => /css/
exports.watchList = [
    [/^.*coffee$/,"coffee -c {fullpath}"]	
    ,[/^.*less$/,"lessc {fullpath} > {directory}{basename}.css"]
]
```
Watchfile is considered as an standard node module and latter running by require("vm").runInContext.
exports.watchList MUST be an Array of 2 dimension.Each of the elements contain [RegExp for matched file,cmdline for what to do when compile]

Consider the folder structure
```
/Watchfile  #this one is the example
/index.html
/js/code.coffee
/css/style.less
```

When running watchcompile at /

```
/js/code.coffee is matched by [/^.*coffee$/,"coffee -c {fullpath}"]
/css/style.less is matched by [/^.*less$/,"lessc {fullpath} > {directory}{basename}.css"]
]
```
So when /js/code.coffee changed."coffee -c /js/code.coffee" is excuted.

When /css/style.less changed."lessc /css/style.less > /css/style.css" is excuted.

Supported place holder are :
```
{basename} /css/style.less => style.less
{fullpath} /css/style.less => /css/style.less (unchanged)
{filename} /css/style.less => style
{extname}  /css/style.less => .less
{directory} /css/style.less => /css/
```
# Note
Since Watchfile is considered and excuted as node module.So you can do what ever you want in side to generate any exports.watchList you want in your own logic.
