# DTrace and LevelDB 


## Using DTrace to View Remenants of LevelDOWN

This is part of a series of gists that aim to give an overview of using dtrace to understand some of the internals of leveldown.
In order to follow the examples clone the dtrace-leveldb-blogpost repo to work along. 

```bash
$ git clone git@github.com:No9/dtrace-leveldb-blogpost.git 
$ cd dtrace-leveldb-blogpost 
$ npm install 
```

## Counting puts

To start we are going to inspect the put command and count how many times it is called by a node program.

To find the the right `put` command first we need to inspect the library.

The following bash commands should be executed from the root folder. 

```bash
$ nm node_modules/level/node_modules/leveldown/build/Release/leveldown.node | grep Put
```

This command inspects the binary and filters for entries that contain `Put`

```
0000000000063fb0 T _ZN7leveldb10PutFixed32EPSsj
0000000000063fe0 T _ZN7leveldb10PutFixed64EPSsm
0000000000059d20 T _ZN7leveldb10WriteBatch3PutERKNS_5SliceES3_
00000000000640a0 T _ZN7leveldb11PutVarint32EPSsj
0000000000064110 T _ZN7leveldb11PutVarint64EPSsm
00000000000597c0 t _ZN7leveldb12_GLOBAL__N_116MemTableInserter3PutERKNS_5SliceES4_
0000000000064150 T _ZN7leveldb22PutLengthPrefixedSliceEPSsRKNS_5SliceE
000000000003e5d0 T _ZN7leveldb2DB3PutERKNS_12WriteOptionsERKNS_5SliceES6_
000000000003e650 T _ZN7leveldb6DBImpl3PutERKNS_12WriteOptionsERKNS_5SliceES6_
00000000000326a0 T _ZN9leveldown5Batch3PutERKN2v89ArgumentsE
0000000000035240 T _ZN9leveldown8Database13PutToDatabaseEPN7leveldb12WriteOptionsENS1_5SliceES4_
0000000000034700 T _ZN9leveldown8Database3PutERKN2v89ArgumentsE
```

There are a number of candidates there so lets see it unmangled using the `-C` option. 

```bash
$ nm -C node_modules/level/node_modules/leveldown/build/Release/leveldown.node | grep Put
```

Now we can see the cleaned output

```
0000000000063fb0 T leveldb::PutFixed32(std::string*, unsigned int)
0000000000063fe0 T leveldb::PutFixed64(std::string*, unsigned long)
0000000000059d20 T leveldb::WriteBatch::Put(leveldb::Slice const&, leveldb::Slice const&)
00000000000640a0 T leveldb::PutVarint32(std::string*, unsigned int)
0000000000064110 T leveldb::PutVarint64(std::string*, unsigned long)
00000000000597c0 t leveldb::(anonymous namespace)::MemTableInserter::Put(leveldb::Slice const&, leveldb::Slice const&)
0000000000064150 T leveldb::PutLengthPrefixedSlice(std::string*, leveldb::Slice const&)
000000000003e5d0 T leveldb::DB::Put(leveldb::WriteOptions const&, leveldb::Slice const&, leveldb::Slice const&)
000000000003e650 T leveldb::DBImpl::Put(leveldb::WriteOptions const&, leveldb::Slice const&, leveldb::Slice const&)
00000000000326a0 T leveldown::Batch::Put(v8::Arguments const&)
0000000000035240 T leveldown::Database::PutToDatabase(leveldb::WriteOptions*, leveldb::Slice, leveldb::Slice)
0000000000034700 T leveldown::Database::Put(v8::Arguments const&)
```

There is also a simple AWK script in the root folder that allows you to see the corresponding lines:

```bash
$ ./join.awk | grep Put

0000000000063fb0 T _ZN7leveldb10PutFixed32EPSsj == leveldb::PutFixed32(std::string*, unsigned int)
0000000000063fe0 T _ZN7leveldb10PutFixed64EPSsm == leveldb::PutFixed64(std::string*, unsigned long)
0000000000059d20 T _ZN7leveldb10WriteBatch3PutERKNS_5SliceES3_ == leveldb::WriteBatch::Put(leveldb::Slice const&, leveldb::Slice const&)
00000000000640a0 T _ZN7leveldb11PutVarint32EPSsj == leveldb::PutVarint32(std::string*, unsigned int)
0000000000064110 T _ZN7leveldb11PutVarint64EPSsm == leveldb::PutVarint64(std::string*, unsigned long)
00000000000597c0 t _ZN7leveldb12_GLOBAL__N_116MemTableInserter3PutERKNS_5SliceES4_ == leveldb::(anonymous namespace)::MemTableInserter::Put(leveldb::Slice const&, leveldb::Slice const&)
0000000000064150 T _ZN7leveldb22PutLengthPrefixedSliceEPSsRKNS_5SliceE == leveldb::PutLengthPrefixedSlice(std::string*, leveldb::Slice const&)
000000000003e5d0 T _ZN7leveldb2DB3PutERKNS_12WriteOptionsERKNS_5SliceES6_ == leveldb::DB::Put(leveldb::WriteOptions const&, leveldb::Slice const&, leveldb::Slice const&)
000000000003e650 T _ZN7leveldb6DBImpl3PutERKNS_12WriteOptionsERKNS_5SliceES6_ == leveldb::DBImpl::Put(leveldb::WriteOptions const&, leveldb::Slice const&, leveldb::Slice const&)
00000000000326a0 T _ZN9leveldown5Batch3PutERKN2v89ArgumentsE == leveldown::Batch::Put(v8::Arguments const&)
0000000000035240 T _ZN9leveldown8Database13PutToDatabaseEPN7leveldb12WriteOptionsENS1_5SliceES4_ == leveldown::Database::PutToDatabase(leveldb::WriteOptions*, leveldb::Slice, leveldb::Slice)
0000000000034700 T _ZN9leveldown8Database3PutERKN2v89ArgumentsE == leveldown::Database::Put(v8::Arguments const&)

```

OK so we are going to target the Put that exposes the V8 call.
```0000000000034700 T leveldown::Database::Put(v8::Arguments const&)```

To do this we are going to create a DTrace file based on the ```leveldown::Database::Put``` symbol.

The file is available in the root folder of the repo  as count-pull.d
Notes: 

1. We add ```:entry``` to ensure we only count the entry to the function not each line of execution within the function

2. pid$1 is used so we can supply the process we wish to examine as a parameter 

```D
#!/usr/sbin/dtrace -s

pid$1::_ZN9leveldown8Database3PutERKN2v89ArgumentsE:entry
{
  @n[probefunc] = count();
}
END
{
  printa(@n);
}
```

Open a terminal and run the index.js script. This will create a put command every 20 seconds.

```bash 
$ node index.js
```

Then in a new terminal run the dtrace script and pipe the output to c++filt for pretty printing.

```bash
$ sudo dtrace -s ./count-put.d `pgrep node` | c++filt
dtrace: script './count-put.d' matched 2 probes
```

In a third terminal find the name of the process that is running dtrace 

```bash 
$ ps aux | grep dtrace 
root      8251  3.6  1.05328830300 pts/2    S 03:17:37  0:01 dtrace -s ./puttra
root      8248  0.1  0.2 9272 3876 pts/2    S 03:17:33  0:00 sudo dtrace -s ./p
```

Once a `put` statement has been emitted from the `node index.js` terminal you can kill the dtrace process from the third terminal with:

```bash
$ sudo kill 8248 
```
Killing the command directly in the terminal running the DTrace script will cause the script to exit and not return any output.
The terminal running the dtrace command will return something like 

```
CPU     ID                    FUNCTION:NAME
  0      2                             :END 
  leveldown::Database::Put(v8::Arguments const&)                      1
```

Well done you can now dtrace leveldb. 

## Measuring Latency

Now we can count put commands we should look at how to quantify the execution time. 

With `node index.js` still running execute latency-put.d 

In essence all we do is create a timestamp when the put function is entered and quantize the difference when the function returns. 

```D
  #!/usr/sbin/dtrace -s
 
  pid$1::_ZN9leveldown8Database3PutERKN2v89ArgumentsE:entry
  {
    self->ts = timestamp;
  }
  
  pid$1::_ZN9leveldown8Database3PutERKN2v89ArgumentsE:return
  /self->ts/
  {
    @[probefunc] = quatize(timestamp - self->ts);
  }
  
  END
  {
    printa("SYSCALL NSECS                        # OF OCCURANCES\n%s%@1x\n", @);
  }

```

Run this script with 

```bash
$ sudo dtrace -s ./latency-put.d `pgrep node` | c++filt
dtrace: script './latency-put.d' matched 3 probes
```
Again wait for the put command in index.js to output a number of times. 

Then find the pid for the dtrace process and kill it as you did for the count trace. 

The output should look like 

```
CPU     ID                    FUNCTION:NAME
  0      2                             :END SYSCALL NSECS                        # OF OCCURANCES
leveldown::Database::Put(v8::Arguments const&)
           value  ------------- Distribution ------------- count    
           32768 |                                         0        
           65536 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 4        
          131072 |                                         0   
```

Where the value is in nano seconds.

Next we will look at logging the parameters the are passed to put. 


