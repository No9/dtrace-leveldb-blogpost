#!/usr/bin/gawk -f

#Load symbols into an array
BEGIN {
   command = "nm node_modules/level/node_modules/leveldown/build/Release/leveldown.node"; 
   i = 0; 
   while ((command | getline) > 0) {
     inp1[i] = $0;
     #print $0; # inpl[i]; 
     #print inp1[i];
     i = i + 1;
 
   }
   
   close(command);

   cleancommand = "nm -C node_modules/level/node_modules/leveldown/build/Release/leveldown.node";
   i = 0;
   while ((cleancommand | getline) > 0) {
     inpl1[i] = (inp1[i] "   " substr($0, index($0,$3)));
     print inpl1[i];
     print " ";
     print " " ;
     i++;
   } 
   close(cleancommand);
}
