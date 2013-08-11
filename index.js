var level = require('level')

var db = level('tests/.db')

setInterval(function(){

db.put('name', { "level" : "FTW" }, function(err) {
  if(err) return console.log(err)
   console.log("put") 
  })

}, 20000)
